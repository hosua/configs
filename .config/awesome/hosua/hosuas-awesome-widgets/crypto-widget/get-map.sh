#!/bin/bash

. .env

CODES="${CODES:-[\"BTC\",\"XMR\",\"ETH\",\"LTC\",\"PAXG\"]}"
FIAT="${FIAT:-USD}"

curl -X POST 'https://api.livecoinwatch.com/coins/map' \
  -H 'content-type: application/json' \
  -H "x-api-key: $LIVECOIN_API_KEY" \
  -d "$(jq -n \
    --argjson codes "$CODES" \
    --arg currency "$FIAT" \
    '{codes: $codes, currency: $currency, sort: "rank", order: "ascending", offset: 0, meta: true}')"
