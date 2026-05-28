import path from "path";
import { existsSync, readFileSync } from "fs";
import tailwindcss from "@tailwindcss/vite";
import react from "@vitejs/plugin-react";
import { defineConfig } from "vite";

const PORT_FILE = path.resolve(__dirname, ".server-port");
const DEFAULT_API_PORT = 42070;

function readApiPort(): number {
  try {
    if (existsSync(PORT_FILE)) {
      return Number(readFileSync(PORT_FILE, "utf8").trim()) || DEFAULT_API_PORT;
    }
  } catch {}
  return DEFAULT_API_PORT;
}

export default defineConfig({
  plugins: [tailwindcss(), react()],
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "./src"),
    },
  },
  server: {
    port: 42069,
    proxy: {
      "/api": `http://localhost:${readApiPort()}`,
    },
  },
});
