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

interface SparkPoint {
  label: string;
  value: number;
}

function buildSparkData(coin: CoinData): SparkPoint[] {
  const rate = coin.rate;
  if (rate == null) return [];

  const points: SparkPoint[] = [];

  const periods: [string, number | null][] = [
    ["1y", coin.delta_year],
    ["90d", coin.delta_quarter],
    ["30d", coin.delta_month],
    ["7d", coin.delta_week],
    ["24h", coin.delta_day],
    ["1h", coin.delta_hour],
  ];

  for (const [label, delta] of periods) {
    if (delta != null && delta > 0) {
      points.push({ label, value: rate / delta });
    }
  }

  points.push({ label: "now", value: rate });
  return points;
}

interface Props {
  coin: CoinData;
  height?: number;
}

export function Sparkline({ coin, height = 52 }: Props) {
  const { hue, accent, accentDim } = useAccent();
  const gradientId = `spark-grad-${coin.code.replace(/[^a-zA-Z0-9]/g, "")}`;

  const data = buildSparkData(coin);
  if (data.length < 2) return null;

  const values = data.map((d) => d.value);
  const min = Math.min(...values);
  const max = Math.max(...values);
  const padding = (max - min) * 0.15 || max * 0.05;

  return (
    <ResponsiveContainer width="100%" height={height}>
      <AreaChart data={data} margin={{ top: 4, right: 0, left: 0, bottom: 0 }}>
        <defs>
          <linearGradient id={gradientId} x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor={`hsl(${hue} 80% 64%)`} stopOpacity={0.3} />
            <stop offset="100%" stopColor={`hsl(${hue} 80% 64%)`} stopOpacity={0} />
          </linearGradient>
        </defs>
        <YAxis domain={[min - padding, max + padding]} hide />
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
            fontSize: "11px",
            color: "hsl(220 13% 91%)",
            padding: "4px 8px",
            boxShadow: `0 4px 12px hsl(${hue} 80% 64% / 0.2)`,
          }}
          formatter={(val) => [
            typeof val === "number" ? `$${formatRate(val)}` : "—",
            "",
          ]}
          labelStyle={{ color: accent, fontWeight: 600 }}
          cursor={{ stroke: accentDim, strokeWidth: 1 }}
        />
      </AreaChart>
    </ResponsiveContainer>
  );
}
