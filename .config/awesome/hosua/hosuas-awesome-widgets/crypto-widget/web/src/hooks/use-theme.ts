import { createContext, useCallback, useContext, useEffect, useState } from "react";

const STORAGE_KEY = "crypto-accent-hue";
export const DEFAULT_HUE = 250;
const S = 80;
const L = 64;

export interface ThemeState {
  hue: number;
  setHue: (h: number) => void;
  accent: string;       // hsl(H S% L%)
  accentDim: string;    // hsl(H S% L% / 0.15)
  accentGlow: string;   // hsl(H S% L% / 0.25)
  accentFaint: string;  // hsl(H S% L% / 0.07)
}

export const ThemeContext = createContext<ThemeState>({
  hue: DEFAULT_HUE,
  setHue: () => {},
  accent: `hsl(${DEFAULT_HUE} ${S}% ${L}%)`,
  accentDim: `hsl(${DEFAULT_HUE} ${S}% ${L}% / 0.15)`,
  accentGlow: `hsl(${DEFAULT_HUE} ${S}% ${L}% / 0.25)`,
  accentFaint: `hsl(${DEFAULT_HUE} ${S}% ${L}% / 0.07)`,
});

export function useAccent(): ThemeState {
  return useContext(ThemeContext);
}

function derive(hue: number): Omit<ThemeState, "hue" | "setHue"> {
  return {
    accent: `hsl(${hue} ${S}% ${L}%)`,
    accentDim: `hsl(${hue} ${S}% ${L}% / 0.15)`,
    accentGlow: `hsl(${hue} ${S}% ${L}% / 0.25)`,
    accentFaint: `hsl(${hue} ${S}% ${L}% / 0.07)`,
  };
}

function applyToCss(hue: number) {
  const root = document.documentElement;
  const base = `${hue} ${S}% ${L}%`;
  root.style.setProperty("--primary", base);
  root.style.setProperty("--ring", base);
  root.style.setProperty("--accent-hue", String(hue));
}

export function useTheme(): ThemeState {
  const [hue, setHueState] = useState<number>(() => {
    try {
      const saved = localStorage.getItem(STORAGE_KEY);
      return saved ? Number(saved) : DEFAULT_HUE;
    } catch {
      return DEFAULT_HUE;
    }
  });

  useEffect(() => {
    applyToCss(hue);
  }, [hue]);

  const setHue = useCallback((h: number) => {
    setHueState(h);
    localStorage.setItem(STORAGE_KEY, String(h));
    applyToCss(h);
  }, []);

  return { hue, setHue, ...derive(hue) };
}
