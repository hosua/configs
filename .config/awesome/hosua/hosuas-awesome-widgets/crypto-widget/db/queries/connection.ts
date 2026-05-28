import "../env-loader";
import Database from "better-sqlite3";
import { resolve } from "path";

export function openReadonly(dbPath?: string): Database.Database {
  const resolved = dbPath ?? resolve(__dirname, "../../crypto.db");
  const db = new Database(resolved, { readonly: true });
  db.pragma("journal_mode = WAL");
  return db;
}
