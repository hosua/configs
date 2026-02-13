#!/bin/bash
# https://livecoinwatch.github.io/lcw-api-docs/#introduction

. .env

CODES='["BTC","XMR","ETH","LTC"]'

curl -X POST 'https://api.livecoinwatch.com/coins/map' \
  -H 'content-type: application/json' \
  -H "x-api-key: $LIVECOIN_API_KEY" \
  -d "$(jq -n \
    --argjson codes "$CODES" \
    '{codes: $codes, currency: "USD", sort: "rank", order: "ascending", offset: 0, meta: false}')"
