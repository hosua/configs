#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Defaults ─────────────────────────────────────────────────────────────────
DEFAULT_FIAT="USD"
DEFAULT_LIMIT="100"
DEFAULT_SORT="rank"
DEFAULT_ORDER="ascending"

VALID_SORTS="rank|price|volume|code|name|age"
VALID_ORDERS="ascending|descending"

# ── Colour helpers ───────────────────────────────────────────────────────────
red()   { printf '\033[31m%s\033[0m\n' "$*" >&2; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
blue()  { printf '\033[34m%s\033[0m\n' "$*"; }
bold()  { printf '\033[1m%s\033[0m\n'  "$*"; }
dim()   { printf '\033[2m%s\033[0m\n'  "$*"; }

# ── Usage ────────────────────────────────────────────────────────────────────
usage() {
    bold "Usage:"
    echo "  ./seed.sh --defaults"
    echo "  ./seed.sh --fiat <FIAT> --limit <N> --sort <field> --order <dir>"
    echo "  ./seed.sh -h | --help"
    echo ""
    bold "Options:"
    printf "  %-24s %s\n" "--defaults"         "Use all default values (shown below)"
    printf "  %-24s %s\n" "--fiat <FIAT>"       "Currency code  (default: ${DEFAULT_FIAT})"
    printf "  %-24s %s\n" "--limit <N>"         "Coins to fetch, 1–100  (default: ${DEFAULT_LIMIT})"
    printf "  %-24s %s\n" "--sort <field>"      "Sort field: ${VALID_SORTS}  (default: ${DEFAULT_SORT})"
    printf "  %-24s %s\n" "--order <dir>"       "Sort direction: ascending|descending  (default: ${DEFAULT_ORDER})"
    printf "  %-24s %s\n" "-h, --help"          "Show this help"
    echo ""
    bold "Examples:"
    dim "  # Fetch top 100 coins by rank in USD (defaults)"
    echo "  ./seed.sh --defaults"
    echo ""
    dim "  # Fetch top 50 coins sorted by volume in EUR"
    echo "  ./seed.sh --fiat EUR --limit 50 --sort volume --order descending"
    echo ""
    dim "  # Via pnpm from project root"
    echo "  pnpm db:seed --defaults"
}

# ── Argument parsing ─────────────────────────────────────────────────────────
FIAT=""
LIMIT=""
SORT=""
ORDER=""
USE_DEFAULTS=false

if [[ $# -eq 0 ]]; then
    usage
    exit 0
fi

while [[ $# -gt 0 ]]; do
    case "$1" in
        --defaults)
            USE_DEFAULTS=true
            shift
            ;;
        --fiat)
            [[ -n "${2:-}" ]] || { red "Error: --fiat requires a value."; exit 1; }
            FIAT="$2"; shift 2
            ;;
        --limit)
            [[ -n "${2:-}" ]] || { red "Error: --limit requires a value."; exit 1; }
            LIMIT="$2"; shift 2
            ;;
        --sort)
            [[ -n "${2:-}" ]] || { red "Error: --sort requires a value."; exit 1; }
            SORT="$2"; shift 2
            ;;
        --order)
            [[ -n "${2:-}" ]] || { red "Error: --order requires a value."; exit 1; }
            ORDER="$2"; shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            red "Error: unknown option '$1'"
            echo ""
            usage
            exit 1
            ;;
    esac
done

# ── Apply defaults ───────────────────────────────────────────────────────────
[[ -z "$FIAT"  ]] && FIAT="$DEFAULT_FIAT"
[[ -z "$LIMIT" ]] && LIMIT="$DEFAULT_LIMIT"
[[ -z "$SORT"  ]] && SORT="$DEFAULT_SORT"
[[ -z "$ORDER" ]] && ORDER="$DEFAULT_ORDER"

# ── Validation ───────────────────────────────────────────────────────────────
if ! [[ "$LIMIT" =~ ^[0-9]+$ ]] || (( LIMIT < 1 || LIMIT > 100 )); then
    red "Error: --limit must be an integer between 1 and 100 (got: ${LIMIT})"
    exit 1
fi

if ! [[ "$SORT" =~ ^(rank|price|volume|code|name|age)$ ]]; then
    red "Error: --sort must be one of: ${VALID_SORTS} (got: ${SORT})"
    exit 1
fi

if ! [[ "$ORDER" =~ ^(ascending|descending)$ ]]; then
    red "Error: --order must be ascending or descending (got: ${ORDER})"
    exit 1
fi

# ── Preflight ────────────────────────────────────────────────────────────────
cd "$SCRIPT_DIR"

[[ -f ".env" ]] || {
    red "Error: .env not found. Copy env.default to .env and set LIVECOIN_API_KEYS."
    exit 1
}

source .env 2>/dev/null || . .env

[[ -n "${LIVECOIN_API_KEYS:-}" ]] || {
    red "Error: LIVECOIN_API_KEYS is not set in .env"
    exit 1
}

command -v pnpm >/dev/null 2>&1 || {
    red "Error: pnpm is required. Install it with: npm install -g pnpm"
    exit 1
}

# ── Step 1: Initialise DB if it doesn't exist ─────────────────────────────────
if [[ ! -f "crypto.db" ]]; then
    blue "crypto.db not found — initialising database..."
    pnpm db:init
fi

# ── Step 2: Fetch live coin data ──────────────────────────────────────────────
mkdir -p data

bold "Fetching coin data..."
blue "  fiat=${FIAT}  limit=${LIMIT}  sort=${SORT}  order=${ORDER}"

FIAT="$FIAT" LIMIT="$LIMIT" SORT="$SORT" ORDER="$ORDER" \
    ./get-list.sh > data/latest.json

COIN_COUNT=$(python3 -c "import json; print(len(json.load(open('data/latest.json'))))" 2>/dev/null || \
    node -e "process.stdout.write(String(JSON.parse(require('fs').readFileSync('data/latest.json')).length))")

green "✓ Fetched ${COIN_COUNT} coins → data/latest.json"

# ── Step 3: Ingest into SQLite ────────────────────────────────────────────────
bold "Ingesting into crypto.db..."
pnpm db:ingest

green "✓ Done — crypto.db is seeded with live data"
