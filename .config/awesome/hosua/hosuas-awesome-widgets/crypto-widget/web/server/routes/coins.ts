import { Hono } from "hono";
import { getCoins } from "../db.js";

const coins = new Hono();

coins.get("/", (c) => {
  const limit = Math.min(Number(c.req.query("limit") ?? 100), 100);
  const data = getCoins(limit);
  return c.json(data);
});

export default coins;
