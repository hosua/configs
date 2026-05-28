import "./env-loader.js";
import { serve } from "@hono/node-server";
import { serveStatic } from "@hono/node-server/serve-static";
import { existsSync, writeFileSync } from "fs";
import { createServer } from "net";
import path from "path";
import { fileURLToPath } from "url";
import { Hono } from "hono";
import { cors } from "hono/cors";
import coins from "./routes/coins.js";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const PORT_FILE = path.join(__dirname, "../.server-port");

function findFreePort(start: number): Promise<number> {
  return new Promise((resolve) => {
    const probe = createServer();
    probe.listen(start, "127.0.0.1", () => {
      probe.close(() => resolve(start));
    });
    probe.on("error", () => resolve(findFreePort(start + 1)));
  });
}

const app = new Hono();
app.use("*", cors());
app.route("/api/coins", coins);

if (existsSync("./dist")) {
  app.use("*", serveStatic({ root: "./dist" }));
  app.use("*", serveStatic({ path: "./dist/index.html" }));
}

const preferredPort = Number(process.env.PORT ?? 42070);
const port = await findFreePort(preferredPort);

if (port !== preferredPort) {
  process.stdout.write(
    `Port ${preferredPort} in use — using ${port} instead\n`,
  );
}

// Write chosen port so Vite proxy can read it
writeFileSync(PORT_FILE, String(port), "utf8");

serve({ fetch: app.fetch, port }, () => {
  process.stdout.write(`API server running on http://localhost:${port}\n`);
});
