# crypto-widget

An AwesomeWM taskbar widget for live cryptocurrency prices, backed by a SQLite time-series database and a local web dashboard.

```
┌──────────────────────────────────────────────────────────┐
│  AwesomeWM widget (Lua)                                  │
│   └─ polls LiveCoinWatch API every 20 s                  │
│   └─ writes data/latest.json                             │
│   └─ spawns DB ingester                                  │
│                                                          │
│  SQLite (crypto.db)                                      │
│   └─ coins · snapshots · supply_snapshots                │
│                                                          │
│  Web dashboard (React + shadcn/ui)           :42069      │
│   └─ Hono API server                         :42070      │
└──────────────────────────────────────────────────────────┘
```

---

## Requirements

| Dependency | Minimum | Notes |
|---|---|---|
| Node.js | 20 | Runtime for DB scripts and web server |
| pnpm | 10 | Workspace package manager (`npm i -g pnpm`) |
| AwesomeWM | 4.x | Lua widget host |
| `curl`, `jq` | any | Used by the shell scripts |
| Docker + Compose | v2 | For the containerised install |
| systemd | any | For the service install |

---

## Quick start (development)

### 1. Get an API key

Sign up at [livecoinwatch.com](https://www.livecoinwatch.com/tools/api) and copy your API key.

### 2. Configure the environment

There is a single `.env` at the project root. All sub-projects read from it automatically — no copying required.

```bash
cp env.default .env
# edit .env and fill in LIVECOIN_API_KEY
```

### 3. Install all dependencies

```bash
pnpm install          # installs db/ and web/ in one shot
# or equivalently:
pnpm install -r
```

### 4. Initialise the database

```bash
pnpm db:init          # creates crypto.db at the project root
```

### 5. Seed with live data

```bash
pnpm db:seed --defaults          # fetch top 100 by rank in USD and ingest
```

Or with custom params:

```bash
pnpm db:seed --fiat EUR --limit 50 --sort volume --order descending
```

Run `pnpm db:seed --help` to see all options.

### 6. Start the web dashboard

```bash
pnpm dev:all          # starts API server (:42070) + Vite (:42069) together
```

Open **http://localhost:42069**.

### 7. Load the AwesomeWM widget

Add to your `rc.lua`:

```lua
local crypto = require("hosuas-awesome-widgets.crypto-widget.crypto-widget")

s.mywibox:setup {
    ...,
    crypto_widget {
        main_coin        = "XMR",   -- coin shown on the taskbar
        fiat             = "USD",
        mode             = "list",  -- "list" = top N by rank, "map" = curated codes
        coins_to_display = 100,
        refresh_rate     = 20,      -- seconds between API calls
    },
    ...,
}
```

Once the widget starts it writes `data/latest.json` and triggers `pnpm run ingest` (in `db/`) on every refresh cycle automatically.

---

## Project structure

```
crypto-widget/
│
│  ── Config ────────────────────────────────────────────────
├── .env                     Runtime secrets and settings — not committed
├── env.default              Template: copy to .env and fill in your key
├── pnpm-workspace.yaml      Declares db/ and web/ as workspace packages
├── package.json             Root package (npm publish target + root scripts)
│
│  ── AwesomeWM widget ──────────────────────────────────────
├── crypto-widget.lua        Main Lua widget
├── get-list.sh              Fetch top-N coins (list mode)
├── get-map.sh               Fetch specific coins by code (map mode)
├── get-fiats.sh             Fetch supported fiat currencies
│
│  ── Database layer ────────────────────────────────────────
├── crypto.db                SQLite database (generated, not committed)
├── data/
│   └── latest.json          Last raw API response — written by the widget
│
├── db/
│   ├── init-db.ts           Creates the 3-table schema
│   ├── ingest.ts            Reads latest.json → dedup → inserts into DB
│   ├── liveCoinWatchApi.ts  Typed wrappers for the LiveCoinWatch REST API
│   ├── cli.ts               CLI: getCoinList | getCoinMap | getFiats
│   ├── types.ts             Shared TypeScript types
│   ├── env-loader.ts        Loads root .env → process.env
│   └── package.json
│
│  ── Web dashboard ─────────────────────────────────────────
├── web/
│   ├── server/
│   │   ├── index.ts         Hono HTTP server (port 42070 / 8081 in Docker)
│   │   ├── db.ts            Reads latest.json or falls back to SQLite
│   │   ├── env-loader.ts    Loads root .env → process.env
│   │   └── routes/
│   │       └── coins.ts     GET /api/coins
│   └── src/
│       ├── App.tsx
│       ├── components/
│       │   ├── coin-card.tsx
│       │   ├── coin-grid.tsx
│       │   ├── coin-icon.tsx
│       │   ├── coin-selector.tsx
│       │   ├── color-picker.tsx
│       │   ├── delta-badge.tsx
│       │   ├── header.tsx
│       │   └── sparkline.tsx
│       ├── hooks/
│       │   ├── use-coins.ts
│       │   └── use-theme.ts
│       └── types/coin.ts
│
│  ── Docker / install ──────────────────────────────────────
├── Dockerfile
├── docker-compose.yml
├── docker-entrypoint.sh
├── nginx.conf
├── install.sh
└── uninstall.sh
```

---

## Environment variables

A single `.env` at the project root is the only file you need to edit. Both `db/env-loader.ts` and `web/server/env-loader.ts` resolve to this file using `__dirname`-relative paths, so they work regardless of which directory you run commands from.

| Variable | Default | Description |
|---|---|---|
| `LIVECOIN_API_KEY` | — | **Required.** Your LiveCoinWatch API key |
| `CURRENCY` | `USD` | Display currency |
| `MAIN_COIN` | `BTC` | Coin shown on the AwesomeWM taskbar |
| `DB_PATH` | `./crypto.db` | Path to the SQLite database file |
| `DEDUP_EPSILON` | `0` | Minimum relative rate change to store a snapshot. `0` = exact match only. `0.0001` = skip changes smaller than 0.01% |

Docker overrides `DB_PATH` and adds `DATA_PATH` via `docker-compose.yml` — no changes to `.env` needed for Docker.

---

## Web dashboard

### Coin grid

- Displays up to 100 coins with icon, ticker, name, rank, and price
- Sparkline chart per card built from the 6 API delta windows (1 h → 1 y)
- Delta badges for 1 h / 24 h / 7 d / 30 d — positive values use your accent colour, negative stays red
- Cards glow in your accent colour on hover

### Coin selector

Click **"All coins"** to open a searchable multiselect. Filter to any subset of coins. Selection persists in `localStorage`.

### Theme / colour picker

The coloured circle in the top-right opens the colour picker. Drag the hue slider or click a preset swatch. The accent colour applies live to sparkline charts, positive delta badges, and card hover glows. Persisted in `localStorage`.

### Data freshness

The API server reads `data/latest.json` (written by the widget every 20 s) as its primary source. It falls back to the SQLite snapshot history only if that file is older than 24 hours. The dashboard auto-refreshes every 30 s.

---

## Database schema

```sql
-- Coin metadata (upserted on every ingestion)
coins (code PK, name, symbol, rank, age, color, png32,
       all_time_high_usd, max_supply, updated_at)

-- Price/delta time series (append-only, dedup-filtered)
snapshots (coin_code, ts, rate, volume, cap,
           delta_hour, delta_day, delta_week,
           delta_month, delta_quarter, delta_year)

-- Circulating / total supply (only stored on change)
supply_snapshots (coin_code, ts, circulating_supply, total_supply)
```

Delta values are stored as **multipliers** (`1.0093` = +0.93%, `0.7279` = -27.21%). Convert to percentage: `(delta - 1) * 100`.

### Useful queries

```sql
-- Latest price for every coin
SELECT c.code, s.rate, datetime(s.ts, 'unixepoch') as updated
FROM coins c
JOIN snapshots s ON s.coin_code = c.code
  AND s.ts = (SELECT MAX(ts) FROM snapshots WHERE coin_code = c.code)
ORDER BY c.rank;

-- XMR/LTC ratio over the last 7 days
SELECT datetime(a.ts, 'unixepoch') as time,
       round(a.rate / b.rate, 4)   as xmr_ltc
FROM snapshots a
JOIN snapshots b ON a.ts = b.ts
WHERE a.coin_code = 'XMR'
  AND b.coin_code = 'LTC'
  AND a.ts > unixepoch('now', '-7 days')
ORDER BY a.ts;

-- Daily OHLC for BTC
SELECT date(ts, 'unixepoch')  as day,
       min(rate)               as low,
       max(rate)               as high,
       first_value(rate) OVER w as open,
       last_value(rate)  OVER w as close
FROM snapshots
WHERE coin_code = 'BTC'
GROUP BY day
WINDOW w AS (PARTITION BY date(ts, 'unixepoch') ORDER BY ts
             ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING);
```

---

## Scripts reference

### Root (run from project root)

```bash
pnpm install           # install all workspace packages (db/ + web/)
pnpm install -r        # explicit recursive form, same result

pnpm dev:all           # API server + Vite dev server together
pnpm dev               # Vite only  (:42069)
pnpm dev:server        # API server only  (:42070)

pnpm db:init           # create / reset crypto.db schema
pnpm db:ingest         # ingest data/latest.json → crypto.db (raw)
pnpm db:seed           # fetch live data + ingest in one step (see --help)

pnpm build:all         # production build of all packages

pnpm docker:build      # docker compose build
pnpm docker:up         # docker compose up -d
pnpm docker:down       # docker compose down
pnpm docker:logs       # docker compose logs -f

pnpm install:service   # sudo install.sh  (requires root)
pnpm uninstall:service # sudo uninstall.sh (requires root)
```

### db/ package (also accessible via `pnpm --filter awesome-crypto-db run <script>`)

```bash
pnpm --filter awesome-crypto-db run initDb
pnpm --filter awesome-crypto-db run ingest
pnpm --filter awesome-crypto-db run getCoinList -- --limit 100
pnpm --filter awesome-crypto-db run getCoinMap  -- --codes BTC,XMR,ETH,LTC
pnpm --filter awesome-crypto-db run getFiats
```

### web/ package (also accessible via `pnpm --filter web run <script>`)

```bash
pnpm --filter web run dev
pnpm --filter web run dev:server
pnpm --filter web run dev:all
pnpm --filter web run build
```

---

## Docker

### Build and run manually

```bash
docker compose build
docker compose up -d
docker compose logs -f
docker compose down
```

| Service | Internal port | Host port |
|---|---|---|
| Frontend (nginx) | 8080 | **42069** |
| API (Hono) | 8081 | **42070** |

`crypto.db` and `data/` are mounted read-only from the project root so the container always serves live data written by the AwesomeWM widget.

---

## Install as a systemd service

### Install

```bash
sudo ./install.sh
```

This will:
1. Check for `docker`, `systemctl`, `rsync`, `pnpm`
2. Copy the project to `/usr/local/share/crypto-widget/`
3. Build the Docker image
4. Install and enable `/etc/systemd/system/crypto-widget.service`
5. Install the `crypto-widget` helper binary to `/usr/local/bin/`

After installation:

```bash
systemctl status  crypto-widget
systemctl stop    crypto-widget
systemctl start   crypto-widget
journalctl -u crypto-widget -f

# or use the installed helper:
crypto-widget status
crypto-widget logs
crypto-widget restart
crypto-widget update    # rebuild image and restart
```

The service starts automatically on boot.

### Uninstall

```bash
sudo ./uninstall.sh           # removes everything
sudo ./uninstall.sh --keep-db # preserves crypto.db (backed up to /tmp/)
```

---

## npm / pnpm package

The root `package.json` defines a publishable package. Once published to npm:

```bash
npm install -g crypto-widget-dashboard
sudo crypto-widget-install
sudo crypto-widget-uninstall
```

---

## Live data flow

```
AwesomeWM widget (every 20 s)
  │
  ├─ GET /coins/list → LiveCoinWatch API
  ├─ writes  → data/latest.json
  └─ runs    → pnpm run ingest  (in db/)
                 │
                 ├─ reads root .env (via db/env-loader.ts)
                 ├─ upserts coin metadata → coins table
                 ├─ appends rate snapshot → snapshots  (dedup by DEDUP_EPSILON)
                 └─ appends supply row    → supply_snapshots (exact-match dedup)

Web dashboard (every 30 s)
  │
  └─ GET /api/coins
       │
       ├─ reads root .env (via web/server/env-loader.ts)
       ├─ reads data/latest.json  (if < 24 h old)  ← always preferred
       └─ falls back to SQLite latest snapshot      ← widget not running
```

---

## Licence

MIT
