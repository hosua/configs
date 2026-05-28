import { useState } from "react";
import { cn } from "@/lib/utils";

interface Props {
  src: string | null;
  code: string;
  color: string | null;
  size?: number;
  className?: string;
}

export function CoinIcon({ src, code, color, size = 32, className }: Props) {
  const [failed, setFailed] = useState(false);

  const fallbackColor = color && color !== "#ffffff" && color !== "#fbfbfb" && color !== "#fcfcfc"
    ? color
    : "#4b5563";

  if (!src || failed) {
    return (
      <div
        className={cn("rounded-full flex items-center justify-center shrink-0", className)}
        style={{
          width: size,
          height: size,
          backgroundColor: fallbackColor,
        }}
      >
        <span
          className="font-bold text-white select-none"
          style={{ fontSize: size * 0.35 }}
        >
          {code.replace(/_/g, "").slice(0, 2)}
        </span>
      </div>
    );
  }

  return (
    <img
      src={src}
      alt={code}
      width={size}
      height={size}
      loading="lazy"
      onError={() => setFailed(true)}
      className={cn("rounded-full shrink-0", className)}
      style={{ width: size, height: size }}
    />
  );
}
