#!/bin/bash

. .env

FIAT="${FIAT:-USD}"
LIMIT="${LIMIT:-100}"

curl -X POST 'https://api.livecoinwatch.com/coins/list' \
  -H 'content-type: application/json' \
  -H "x-api-key: $LIVECOIN_API_KEY" \
  -d "{\"currency\":\"$FIAT\",\"sort\":\"rank\",\"order\":\"ascending\",\"offset\":0,\"limit\":$LIMIT,\"meta\":true}"
