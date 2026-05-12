import axios from "axios";

import type { CoinSort, Order } from "./types";

const LIVECOIN_API_KEY = process.env.LIVECOIN_API_KEY;
const BASE_URL = "https://api.livecoinwatch.com/";

if (!LIVECOIN_API_KEY) {
  throw new Error("LIVECOIN_API_KEY is not set");
}

const HEADERS = { "x-api-key": LIVECOIN_API_KEY };

const getFiats = async () => {
  const { data } = await axios.post(`${BASE_URL}fiats/all`, null, {
    headers: HEADERS,
  });
  return data;
};

interface GetCoinListProps {
  currency?: string;
  sort?: CoinSort;
  order?: Order;
  offset?: number;
  limit?: number; // max 100
}

const getCoinList = async ({
  currency = "USD",
  sort = "rank",
  order = "ascending",
  offset = 0,
  limit = 100,
}: GetCoinListProps = {}) => {
  const { data } = await axios.post(
    `${BASE_URL}coins/list`,
    { currency, sort, order, offset, limit, meta: true },
    { headers: HEADERS }
  );
  return data;
};

interface GetCoinMapProps {
  codes: string[];
  currency?: string;
  sort?: CoinSort;
  order?: Order;
  offset?: number;
}

const getCoinMap = async ({
  codes,
  currency = "USD",
  sort = "rank",
  order = "ascending",
  offset = 0,
}: GetCoinMapProps) => {
  const { data } = await axios.post(
    `${BASE_URL}coins/map`,
    { codes, currency, sort, order, offset, meta: true },
    { headers: HEADERS }
  );
  return data;
};

export { getFiats, getCoinList, getCoinMap };
export default { getFiats, getCoinList, getCoinMap };
