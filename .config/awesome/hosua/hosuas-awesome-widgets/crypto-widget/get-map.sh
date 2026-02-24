#!/bin/bash

. .env

CODES="${CODES:-[\"BTC\",\"XMR\",\"ETH\",\"LTC\",\"PAXG\"]}"
FIAT="${FIAT:-USD}"
SORT="${SORT:-rank}"
ORDER="${ORDER:-ascending}"

curl -X POST 'https://api.livecoinwatch.com/coins/map' \
  -H 'content-type: application/json' \
  -H "x-api-key: $LIVECOIN_API_KEY" \
  -d "$(jq -n \
    --argjson codes "$CODES" \
    --arg currency "$FIAT" \
    --arg sort "$SORT" \
    --arg order "$ORDER" \
    '{codes: $codes, currency: $currency, sort: $sort, order: $order, offset: 0, meta: true}')"
