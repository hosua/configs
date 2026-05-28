import { readFileSync } from "fs";
import { resolve } from "path";

// __dirname is the db/ directory; root .env is one level up
const envPath = resolve(__dirname, "../.env");

try {
  const content = readFileSync(envPath, "utf8");
  for (const line of content.split("\n")) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith("#")) continue;
    const withoutExport = trimmed.replace(/^export\s+/, "");
    const eqIdx = withoutExport.indexOf("=");
    if (eqIdx === -1) continue;
    const key = withoutExport.slice(0, eqIdx).trim();
    const val = withoutExport.slice(eqIdx + 1).trim().replace(/^["']|["']$/g, "");
    if (!process.env[key]) process.env[key] = val;
  }
} catch {}
