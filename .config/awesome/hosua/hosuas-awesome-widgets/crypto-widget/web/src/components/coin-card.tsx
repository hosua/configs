import { useState } from "react";
import { Card, CardContent } from "@/components/ui/card";
import { CoinIcon } from "@/components/coin-icon";
import { DeltaBadge } from "@/components/delta-badge";
import { Sparkline } from "@/components/sparkline";
import { formatRate, formatVolume, stripUnderscores } from "@/lib/format";
import { useAccent } from "@/hooks/use-theme";
import type { CoinData } from "@/types/coin";

interface Props {
  coin: CoinData;
}

export function CoinCard({ coin }: Props) {
  const { accentGlow, accentDim } = useAccent();
  const [hovered, setHovered] = useState(false);
  const displayCode = stripUnderscores(coin.code);

  return (
    <Card
      className="bg-card border transition-all duration-200"
      style={{
        borderColor: hovered ? accentDim : "hsl(228 14% 17%)",
        boxShadow: hovered
          ? `0 0 20px ${accentGlow}, 0 4px 12px hsl(0 0% 0% / 0.3)`
          : undefined,
      }}
      onMouseEnter={() => setHovered(true)}
      onMouseLeave={() => setHovered(false)}
    >
      <CardContent className="p-4 flex flex-col gap-2.5">
        {/* Header */}
        <div className="flex items-center gap-2.5">
          <CoinIcon
            src={coin.png32}
            code={displayCode}
            color={coin.color}
            size={28}
          />
          <div className="flex flex-col min-w-0">
            <span className="text-sm font-semibold text-foreground leading-none">
              {displayCode}
            </span>
            <span className="text-xs text-muted-foreground truncate leading-tight mt-0.5">
              {coin.name}
            </span>
          </div>
          {coin.rank != null && (
            <span className="ml-auto text-xs text-muted-foreground/40 tabular-nums">
              #{coin.rank}
            </span>
          )}
        </div>

        {/* Price */}
        <div>
          <div className="text-base font-mono font-semibold tabular-nums text-foreground">
            {coin.rate != null ? `$${formatRate(coin.rate)}` : "—"}
          </div>
          {coin.volume != null && (
            <div className="text-[11px] text-muted-foreground/70">
              Vol {formatVolume(coin.volume)}
            </div>
          )}
        </div>

        {/* Sparkline */}
        <div className="-mx-1">
          <Sparkline coin={coin} height={140} />
        </div>

        {/* Deltas */}
        <div
          className="flex items-end justify-between border-t pt-2"
          style={{ borderColor: "hsl(228 14% 17%)" }}
        >
          <DeltaBadge value={coin.delta_hour} label="1h" />
          <DeltaBadge value={coin.delta_day} label="24h" />
          <DeltaBadge value={coin.delta_week} label="7d" />
          <DeltaBadge value={coin.delta_month} label="30d" />
          <DeltaBadge value={coin.delta_year} label="1y" />
        </div>
      </CardContent>
    </Card>
  );
}
