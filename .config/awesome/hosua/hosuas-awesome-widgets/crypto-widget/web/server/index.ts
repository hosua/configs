import { serve } from "@hono/node-server";
import { serveStatic } from "@hono/node-server/serve-static";
import { existsSync } from "fs";
import { Hono } from "hono";
import { cors } from "hono/cors";
import coins from "./routes/coins.js";

const app = new Hono();

app.use("*", cors());
app.route("/api/coins", coins);

// Serve built frontend only when dist/ exists (production)
if (existsSync("./dist")) {
  app.use("*", serveStatic({ root: "./dist" }));
  app.use("*", serveStatic({ path: "./dist/index.html" }));
}

const port = Number(process.env.PORT ?? 3001);
serve({ fetch: app.fetch, port }, () => {
  process.stdout.write(`API server running on http://localhost:${port}\n`);
});
