import { formatDeltaPercent } from "@/lib/format";
import { useAccent } from "@/hooks/use-theme";

interface Props {
  value: number | null;
  label: string;
}

export function DeltaBadge({ value, label }: Props) {
  const { accent, accentFaint } = useAccent();

  if (value == null) {
    return (
      <div className="flex flex-col items-center gap-0.5">
        <span className="text-[10px] text-muted-foreground font-mono">—</span>
        <span className="text-[9px] text-muted-foreground/60">{label}</span>
      </div>
    );
  }

  const pct = (value - 1) * 100;
  const isPos = pct > 0;
  const isNeg = pct < 0;

  return (
    <div className="flex flex-col items-center gap-0.5">
      <span
        className="text-[10px] font-mono font-medium tabular-nums px-1 py-0.5 rounded"
        style={
          isPos
            ? { color: accent, background: accentFaint }
            : isNeg
              ? { color: "hsl(0 63% 65%)", background: "hsl(0 63% 65% / 0.08)" }
              : { color: "hsl(220 13% 50%)", background: "hsl(220 13% 20% / 0.5)" }
        }
      >
        {formatDeltaPercent(value)}
      </span>
      <span className="text-[9px] text-muted-foreground/60">{label}</span>
    </div>
  );
}
