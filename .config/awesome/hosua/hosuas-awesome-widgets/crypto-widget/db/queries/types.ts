export interface TimeRange {
  from?: number;
  to?: number;
}

export interface CoinSummary {
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

export interface SnapshotRow {
  coin_code: string;
  ts: number;
  rate: number;
  volume: number | null;
  cap: number | null;
  delta_hour: number | null;
  delta_day: number | null;
  delta_week: number | null;
  delta_month: number | null;
  delta_quarter: number | null;
  delta_year: number | null;
}

export interface ComparePoint {
  bucket: number;
  [coinCode: string]: number | null;
}

export type DeltaPeriod = "hour" | "day" | "week" | "month" | "quarter" | "year";

export interface GainerLoser {
  code: string;
  name: string;
  rank: number | null;
  rate: number;
  delta: number | null;
  period: DeltaPeriod;
}

export interface SupplyPoint {
  coin_code: string;
  ts: number;
  circulating_supply: number | null;
  total_supply: number | null;
}
