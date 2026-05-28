export type CoinSort = "rank" | "price" | "volume" | "code" | "name" | "age";

export type Order = "ascending" | "descending";

export interface Delta {
  hour: number;
  day: number;
  week: number;
  month: number;
  quarter: number;
  year: number;
}

export interface CoinEntry {
  code: string;
  name: string;
  symbol?: string | null;
  rank?: number | null;
  age?: number | null;
  color?: string | null;
  png32?: string | null;
  allTimeHighUSD?: number | null;
  circulatingSupply?: number | null;
  totalSupply?: number | null;
  maxSupply?: number | null;
  rate: number;
  volume?: number | null;
  cap?: number | null;
  delta?: Delta | null;
}
