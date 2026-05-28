import { useRef, useState, useEffect, useMemo, useCallback } from "react";
import {
  AreaChart,
  Area,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";
import type { CoinData } from "@/types/coin";
import { formatRate } from "@/lib/format";
import { useAccent } from "@/hooks/use-theme";
import { useCoinHistory } from "@/hooks/use-coin-history";
import type { HistoryPoint } from "@/hooks/use-coin-history";

// Allowed tick intervals in seconds: 1m 5m 15m 30m 60m 2h 6h 12h 24h 1wk 2wk 1mo
const TICK_INTERVALS = [60, 300, 900, 1800, 3600, 7200, 21600, 43200, 86400, 604800, 1209600, 2592000];
const THREE_DAYS_S = 3 * 86400;
const MAX_HOVER_POINTS = 400;

function pickTickInterval(rangeS: number): number {
  const target = rangeS / 6;
  return TICK_INTERVALS.find((i) => i >= target) ?? TICK_INTERVALS[TICK_INTERVALS.length - 1];
}

function genTicks(left: number, right: number): number[] {
  const interval = pickTickInterval(right - left);
  const first = Math.ceil(left / interval) * interval;
  const ticks: number[] = [];
  for (let t = first; t <= right; t += interval) ticks.push(t);
  return ticks;
}

function fmtTick(ts: number, rangeS: number): string {
  const d = new Date(ts * 1000);
  if (rangeS <= 7200) {
    return d.toLocaleTimeString("en-US", { hour: "2-digit", minute: "2-digit", hour12: false });
  }
  if (rangeS <= 172800) {
    return d.toLocaleString("en-US", {
      month: "short", day: "numeric",
      hour: "2-digit", minute: "2-digit", hour12: false,
    }).replace(",", "");
  }
  return d.toLocaleDateString("en-US", { month: "short", day: "numeric" });
}

function fmtTooltipTs(ts: number): string {
  return new Date(ts * 1000).toLocaleString("en-US", {
    month: "short", day: "numeric",
    hour: "2-digit", minute: "2-digit", hour12: false,
  });
}

function fmtYAxis(val: number): string {
  if (val >= 1e6) return `$${(val / 1e6).toFixed(2)}M`;
  if (val >= 1e3) return `$${(val / 1e3).toFixed(1)}K`;
  if (val >= 1) return `$${val.toFixed(2)}`;
  return `$${val.toPrecision(3)}`;
}

function downsample(points: HistoryPoint[], max: number): HistoryPoint[] {
  if (points.length <= max) return points;
  const stride = Math.ceil(points.length / max);
  return points.filter((_, i) => i % stride === 0 || i === points.length - 1);
}

// Fallback: build pseudo-history from delta multipliers when real data is unavailable
interface SparkPoint { label: string; value: number }
function buildFallbackData(coin: CoinData): SparkPoint[] {
  const rate = coin.rate;
  if (rate == null) return [];
  const periods: [string, number | null][] = [
    ["1y", coin.delta_year],
    ["90d", coin.delta_quarter],
    ["30d", coin.delta_month],
    ["7d", coin.delta_week],
    ["24h", coin.delta_day],
    ["1h", coin.delta_hour],
  ];
  const points: SparkPoint[] = [];
  for (const [label, delta] of periods) {
    if (delta != null && delta > 0) points.push({ label, value: rate / delta });
  }
  points.push({ label: "now", value: rate });
  return points;
}

interface Props {
  coin: CoinData;
  height?: number;
}

// ── Fallback mini-sparkline (shown while history loads / if no data) ──────────
function FallbackSparkline({ coin, height, gradientId, accent, accentDim, hue }: {
  coin: CoinData; height: number; gradientId: string;
  accent: string; accentDim: string; hue: number;
}) {
  const data = buildFallbackData(coin);
  if (data.length < 2) return null;

  const values = data.map((d) => d.value);
  const min = Math.min(...values);
  const max = Math.max(...values);
  const pad = (max - min) * 0.15 || max * 0.05;

  return (
    <div style={{ height, position: "relative" }}>
      <ResponsiveContainer width="100%" height="100%">
        <AreaChart data={data} margin={{ top: 4, right: 0, left: 0, bottom: 0 }}>
          <defs>
            <linearGradient id={gradientId} x1="0" y1="0" x2="0" y2="1">
              <stop offset="0%" stopColor={`hsl(${hue} 80% 64%)`} stopOpacity={0.3} />
              <stop offset="100%" stopColor={`hsl(${hue} 80% 64%)`} stopOpacity={0} />
            </linearGradient>
          </defs>
          <YAxis domain={[min - pad, max + pad]} hide />
          <XAxis dataKey="label" hide />
          <Area
            type="monotone"
            dataKey="value"
            stroke={accent}
            strokeWidth={1.75}
            fill={`url(#${gradientId})`}
            dot={false}
            isAnimationActive={false}
            activeDot={{ r: 3, fill: accent, stroke: "hsl(228 14% 11%)", strokeWidth: 1.5 }}
          />
          <Tooltip
            contentStyle={{
              background: "hsl(228 14% 13%)",
              border: `1px solid ${accentDim}`,
              borderRadius: "6px",
              fontSize: 11,
              color: "hsl(220 13% 91%)",
              padding: "4px 8px",
            }}
            formatter={(val: unknown) => [
              typeof val === "number" ? `$${formatRate(val)}` : "—",
              "",
            ]}
            labelStyle={{ color: accent, fontWeight: 600 }}
            cursor={{ stroke: accentDim, strokeWidth: 1 }}
          />
        </AreaChart>
      </ResponsiveContainer>
    </div>
  );
}

// ── Full interactive chart ────────────────────────────────────────────────────
export function Sparkline({ coin, height = 140 }: Props) {
  const { hue, accent, accentDim } = useAccent();
  const gradientId = `spark-grad-${coin.code.replace(/[^a-zA-Z0-9]/g, "")}`;

  const containerRef = useRef<HTMLDivElement>(null);
  const { data: history, isError } = useCoinHistory(coin.code);

  const [viewLeft, setViewLeft] = useState<number | null>(null);
  const [viewRight, setViewRight] = useState<number | null>(null);
  const [isDragging, setIsDragging] = useState(false);
  const dragRef = useRef<{ startX: number; left: number; right: number } | null>(null);
  const initializedRef = useRef(false);

  // Initialize view once when data arrives
  useEffect(() => {
    if (!history || history.length === 0) return;
    if (initializedRef.current) return;
    initializedRef.current = true;
    const right = history[history.length - 1].ts;
    const left = Math.max(right - THREE_DAYS_S, history[0].ts);
    setViewLeft(left);
    setViewRight(right);
  }, [history]);

  const clampView = useCallback(
    (left: number, right: number) => {
      if (!history || history.length === 0) return;
      const dataMin = history[0].ts;
      const dataMax = history[history.length - 1].ts;
      if (right - left < 60) return;
      setViewLeft(Math.max(left, dataMin));
      setViewRight(Math.min(right, dataMax));
    },
    [history],
  );

  const handleWheel = useCallback(
    (e: WheelEvent) => {
      e.preventDefault();
      if (viewLeft === null || viewRight === null || !history) return;
      const factor = e.deltaY > 0 ? 1.25 : 0.8;
      const range = viewRight - viewLeft;
      const center = (viewLeft + viewRight) / 2;
      clampView(center - (range * factor) / 2, center + (range * factor) / 2);
    },
    [viewLeft, viewRight, history, clampView],
  );

  useEffect(() => {
    const el = containerRef.current;
    if (!el) return;
    el.addEventListener("wheel", handleWheel, { passive: false });
    return () => el.removeEventListener("wheel", handleWheel);
  }, [handleWheel]);

  const onMouseDown = useCallback(
    (e: React.MouseEvent) => {
      if (viewLeft === null || viewRight === null) return;
      dragRef.current = { startX: e.clientX, left: viewLeft, right: viewRight };
      setIsDragging(true);
    },
    [viewLeft, viewRight],
  );

  const onMouseMove = useCallback(
    (e: React.MouseEvent) => {
      if (!dragRef.current || !containerRef.current || !history) return;
      const { startX, left, right } = dragRef.current;
      const dx = e.clientX - startX;
      const w = containerRef.current.clientWidth;
      const timePerPx = (right - left) / w;
      clampView(left - dx * timePerPx, right - dx * timePerPx);
    },
    [history, clampView],
  );

  const onMouseUp = useCallback(() => {
    dragRef.current = null;
    setIsDragging(false);
  }, []);

  const visibleData = useMemo(() => {
    if (!history || viewLeft === null || viewRight === null) return [];
    const filtered = history.filter((d) => d.ts >= viewLeft && d.ts <= viewRight);
    return downsample(filtered, MAX_HOVER_POINTS);
  }, [history, viewLeft, viewRight]);

  const xTicks = useMemo(() => {
    if (viewLeft === null || viewRight === null) return [];
    return genTicks(viewLeft, viewRight);
  }, [viewLeft, viewRight]);

  const yDomain = useMemo<[number, number]>(() => {
    if (visibleData.length === 0) return [0, 1];
    const vals = visibleData.map((d) => d.rate);
    const min = Math.min(...vals);
    const max = Math.max(...vals);
    const pad = (max - min) * 0.12 || max * 0.05;
    return [min - pad, max + pad];
  }, [visibleData]);

  const pctChange = useMemo(() => {
    if (visibleData.length < 2) return null;
    const first = visibleData[0].rate;
    const last = visibleData[visibleData.length - 1].rate;
    return ((last - first) / first) * 100;
  }, [visibleData]);

  const rangeS = (viewRight ?? 0) - (viewLeft ?? 0);
  const isPositive = pctChange === null || pctChange >= 0;

  // Fall back to delta sparkline if history unavailable or too sparse
  if (!history || history.length < 2 || visibleData.length < 2 || isError) {
    return (
      <FallbackSparkline
        coin={coin}
        height={height}
        gradientId={gradientId}
        accent={accent}
        accentDim={accentDim}
        hue={hue}
      />
    );
  }

  return (
    <div
      ref={containerRef}
      style={{
        height,
        position: "relative",
        cursor: isDragging ? "grabbing" : "grab",
        userSelect: "none",
      }}
      onMouseDown={onMouseDown}
      onMouseMove={onMouseMove}
      onMouseUp={onMouseUp}
      onMouseLeave={onMouseUp}
    >
      {/* % change label for the visible window */}
      {pctChange !== null && (
        <div
          style={{
            position: "absolute",
            top: 2,
            right: 60,
            zIndex: 10,
            fontSize: 10,
            fontWeight: 700,
            lineHeight: 1,
            color: isPositive ? "hsl(142 71% 45%)" : "hsl(0 72% 51%)",
            pointerEvents: "none",
          }}
        >
          {isPositive ? "+" : ""}
          {pctChange.toFixed(2)}%
        </div>
      )}

      <ResponsiveContainer width="100%" height="100%">
        <AreaChart data={visibleData} margin={{ top: 14, right: 4, left: 0, bottom: 0 }}>
          <defs>
            <linearGradient id={gradientId} x1="0" y1="0" x2="0" y2="1">
              <stop offset="0%" stopColor={`hsl(${hue} 80% 64%)`} stopOpacity={0.3} />
              <stop offset="100%" stopColor={`hsl(${hue} 80% 64%)`} stopOpacity={0} />
            </linearGradient>
          </defs>

          <XAxis
            dataKey="ts"
            type="number"
            scale="time"
            domain={[viewLeft ?? "auto", viewRight ?? "auto"]}
            ticks={xTicks}
            tickFormatter={(ts: number) => fmtTick(ts, rangeS)}
            tick={{ fontSize: 8, fill: "hsl(220 13% 50%)" }}
            tickLine={false}
            axisLine={false}
            minTickGap={40}
          />

          <YAxis
            domain={yDomain}
            tickFormatter={fmtYAxis}
            tick={{ fontSize: 8, fill: "hsl(220 13% 50%)" }}
            tickLine={false}
            axisLine={false}
            width={56}
            tickCount={4}
          />

          <Area
            type="monotone"
            dataKey="rate"
            stroke={accent}
            strokeWidth={1.5}
            fill={`url(#${gradientId})`}
            dot={false}
            isAnimationActive={false}
            activeDot={
              isDragging
                ? false
                : { r: 3, fill: accent, stroke: "hsl(228 14% 11%)", strokeWidth: 1.5 }
            }
          />

          {!isDragging && (
            <Tooltip
              contentStyle={{
                background: "hsl(228 14% 13%)",
                border: `1px solid ${accentDim}`,
                borderRadius: "6px",
                fontSize: 10,
                color: "hsl(220 13% 91%)",
                padding: "4px 8px",
                boxShadow: `0 4px 12px hsl(${hue} 80% 64% / 0.15)`,
              }}
              formatter={(val: unknown) => [
                typeof val === "number" ? `$${formatRate(val)}` : "—",
                "Rate",
              ]}
              labelFormatter={(ts) => fmtTooltipTs(Number(ts))}
              labelStyle={{ color: "hsl(220 13% 60%)", fontWeight: 500, marginBottom: 2 }}
              cursor={{ stroke: accentDim, strokeWidth: 1 }}
            />
          )}
        </AreaChart>
      </ResponsiveContainer>
    </div>
  );
}
