import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from "@/components/ui/popover";
import { Slider } from "@/components/ui/slider";
import { useAccent } from "@/hooks/use-theme";

const PRESETS = [
  { label: "Purple", hue: 250 },
  { label: "Blue", hue: 217 },
  { label: "Cyan", hue: 189 },
  { label: "Green", hue: 142 },
  { label: "Orange", hue: 25 },
  { label: "Red", hue: 0 },
  { label: "Pink", hue: 330 },
];

export function ColorPicker() {
  const { hue, setHue, accent } = useAccent();

  return (
    <Popover>
      <PopoverTrigger asChild>
        <button
          className="w-5 h-5 rounded-full border-2 border-white/20 hover:border-white/40 transition-all hover:scale-110 shrink-0"
          style={{
            backgroundColor: accent,
            boxShadow: `0 0 8px ${accent}60`,
          }}
          aria-label="Customize accent color"
        />
      </PopoverTrigger>
      <PopoverContent
        className="w-64 p-4 bg-popover border-border"
        align="end"
        style={{ boxShadow: `0 8px 32px hsl(${hue} 80% 10% / 0.6)` }}
      >
        <p className="text-xs text-muted-foreground mb-3 font-medium tracking-wide uppercase">
          Theme color
        </p>

        {/* Live preview bar */}
        <div
          className="w-full h-1 rounded-full mb-4"
          style={{
            background: `linear-gradient(to right, hsl(${hue} 80% 40%), hsl(${hue} 80% 64%), hsl(${hue} 80% 80%))`,
            boxShadow: `0 0 8px hsl(${hue} 80% 64% / 0.5)`,
          }}
        />

        {/* Hue slider */}
        <div
          className="w-full h-3 rounded-full mb-4 relative"
          style={{
            background:
              "linear-gradient(to right, hsl(0,80%,64%), hsl(30,80%,64%), hsl(60,80%,64%), hsl(90,80%,64%), hsl(120,80%,64%), hsl(150,80%,64%), hsl(180,80%,64%), hsl(210,80%,64%), hsl(240,80%,64%), hsl(270,80%,64%), hsl(300,80%,64%), hsl(330,80%,64%), hsl(360,80%,64%))",
          }}
        >
          <Slider
            min={0}
            max={360}
            step={1}
            value={[hue]}
            onValueChange={(vals) => setHue(vals[0])}
            className="w-full"
          />
        </div>

        {/* Presets */}
        <div className="flex flex-wrap gap-2">
          {PRESETS.map((p) => (
            <button
              key={p.hue}
              onClick={() => setHue(p.hue)}
              title={p.label}
              className="w-7 h-7 rounded-full border-2 transition-all hover:scale-110"
              style={{
                backgroundColor: `hsl(${p.hue} 80% 64%)`,
                borderColor: hue === p.hue ? "white" : "transparent",
                boxShadow:
                  hue === p.hue
                    ? `0 0 8px hsl(${p.hue} 80% 64% / 0.8)`
                    : undefined,
              }}
            />
          ))}
        </div>
      </PopoverContent>
    </Popover>
  );
}
