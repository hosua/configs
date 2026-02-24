#!/bin/bash

. .env

FIAT="${FIAT:-USD}"
LIMIT="${LIMIT:-100}"
SORT="${SORT:-rank}"
ORDER="${ORDER:-ascending}"

curl -X POST 'https://api.livecoinwatch.com/coins/list' \
  -H 'content-type: application/json' \
  -H "x-api-key: $LIVECOIN_API_KEY" \
  -d "{\"currency\":\"$FIAT\",\"sort\":\"$SORT\",\"order\":\"$ORDER\",\"offset\":0,\"limit\":$LIMIT,\"meta\":true}"
