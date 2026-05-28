import { ColorPicker } from "@/components/color-picker";
import { Activity } from "lucide-react";

interface Props {
  coinCount: number;
  lastUpdated: number | null;
}

export function Header({ coinCount, lastUpdated }: Props) {
  const timeStr = lastUpdated
    ? new Date(lastUpdated * 1000).toLocaleTimeString()
    : null;

  return (
    <header className="sticky top-0 z-10 border-b border-border bg-background/80 backdrop-blur-sm">
      <div className="max-w-screen-2xl mx-auto px-6 h-14 flex items-center gap-3">
        <Activity className="w-4 h-4 text-primary" strokeWidth={2.5} />
        <span className="text-sm font-semibold text-foreground tracking-tight">
          Crypto
        </span>

        <div className="flex items-center gap-1.5 ml-1">
          <span className="text-xs text-muted-foreground">
            {coinCount > 0 ? `${coinCount} coins` : ""}
          </span>
          {timeStr && (
            <>
              <span className="text-muted-foreground/40">·</span>
              <span className="text-xs text-muted-foreground/60">
                Updated {timeStr}
              </span>
            </>
          )}
        </div>

        <div className="ml-auto flex items-center gap-3">
          <ColorPicker />
        </div>
      </div>
    </header>
  );
}
