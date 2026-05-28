import { Hono } from "hono";
import { getCoins, getCoinHistory } from "../db.js";

const coins = new Hono();

coins.get("/", (c) => {
  const limit = Math.min(Number(c.req.query("limit") ?? 100), 100);
  const data = getCoins(limit);
  return c.json(data);
});

coins.get("/:code/history", (c) => {
  const code = c.req.param("code");
  const days = Math.min(Number(c.req.query("days") ?? 3), 30);
  const data = getCoinHistory(code, days);
  return c.json(data);
});

export default coins;
