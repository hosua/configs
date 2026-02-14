#!/bin/bash

. .env

curl -X POST 'https://api.livecoinwatch.com/coins/list' \
  -H 'content-type: application/json' \
  -H "x-api-key: $LIVECOIN_API_KEY" \
  -d "{\"currency\":\"$CURRENCY\",\"sort\":\"rank\",\"order\":\"ascending\",\"offset\":0,\"limit\":100,\"meta\":true}"
