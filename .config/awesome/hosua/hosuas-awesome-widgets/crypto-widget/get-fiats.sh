#!/bin/bash

. .env

IFS=',' read -ra API_KEYS <<< "$LIVECOIN_API_KEYS"

if [[ ${#API_KEYS[@]} -eq 0 ]]; then
  echo "Error: LIVECOIN_API_KEYS is not set" >&2
  exit 1
fi

for key in "${API_KEYS[@]}"; do
  response=$(curl -s -f -X POST 'https://api.livecoinwatch.com/fiats/all' \
    -H 'content-type: application/json' \
    -H "x-api-key: $key")
  if [[ $? -eq 0 && -n "$response" ]]; then
    echo "$response"
    exit 0
  fi
done

echo "Error: all API keys exhausted" >&2
exit 1
