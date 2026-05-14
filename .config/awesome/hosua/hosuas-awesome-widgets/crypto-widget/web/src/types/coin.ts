export interface CoinData {
  code: string;
  name: string;
  symbol: string | null;
  rank: number | null;
  color: string | null;
  png32: string | null;
  all_time_high_usd: number | null;
  max_supply: number | null;
  rate: number | null;
  volume: number | null;
  cap: number | null;
  ts: number | null;
  delta_hour: number | null;
  delta_day: number | null;
  delta_week: number | null;
  delta_month: number | null;
  delta_quarter: number | null;
  delta_year: number | null;
}
