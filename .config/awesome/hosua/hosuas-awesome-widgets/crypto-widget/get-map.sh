#!/bin/bash

. .env

CODES="${CODES:-[\"BTC\",\"XMR\",\"XRP\",\"ETH\",\"LTC\",\"PAXG\"]}"
FIAT="${FIAT:-USD}"
SORT="${SORT:-rank}"
ORDER="${ORDER:-ascending}"

IFS=',' read -ra API_KEYS <<<"$LIVECOIN_API_KEYS"

if [[ ${#API_KEYS[@]} -eq 0 ]]; then
  echo "Error: LIVECOIN_API_KEYS is not set" >&2
  exit 1
fi

body=$(jq -n \
  --argjson codes "$CODES" \
  --arg currency "$FIAT" \
  --arg sort "$SORT" \
  --arg order "$ORDER" \
  '{codes: $codes, currency: $currency, sort: $sort, order: $order, offset: 0, meta: true}')

for key in "${API_KEYS[@]}"; do
  response=$(curl -s -f -X POST 'https://api.livecoinwatch.com/coins/map' \
    -H 'content-type: application/json' \
    -H "x-api-key: $key" \
    -d "$body")
  if [[ $? -eq 0 && -n "$response" ]]; then
    echo "$response"
    exit 0
  fi
done

echo "Error: all API keys exhausted" >&2
exit 1
