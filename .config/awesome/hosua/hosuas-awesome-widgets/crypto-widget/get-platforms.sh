#!/bin/bash

. .env

curl -X POST 'https://api.livecoinwatch.com/platforms/all' \
  -H 'content-type: application/json' \
  -H "x-api-key: $LIVECOIN_API_KEY"
