#!/bin/bash
# fetch-usage.sh
# Uses the Claude Code OAuth token to fetch usage data from the Anthropic API.
# Parses anthropic-ratelimit-unified-* headers for 5h and 7d windows.
# Outputs key=value pairs for Lua parsing.

CREDS="$HOME/.claude/.credentials.json"

if [ ! -f "$CREDS" ]; then
    echo "error=no_credentials"
    exit 0
fi

TOKEN=$(python3 -c "
import json, sys
try:
    d = json.load(open('$CREDS'))
    print(d['claudeAiOauth']['accessToken'])
except Exception as e:
    print('', end='')
" 2>/dev/null)

if [ -z "$TOKEN" ]; then
    echo "error=no_token"
    exit 0
fi

RESPONSE=$(curl -s -D - -o /dev/null \
    -X POST "https://api.anthropic.com/v1/messages" \
    -H "Authorization: Bearer $TOKEN" \
    -H "anthropic-version: 2023-06-01" \
    -H "content-type: application/json" \
    -d '{"model":"claude-haiku-4-5-20251001","max_tokens":1,"messages":[{"role":"user","content":"x"}]}' \
    2>/dev/null)

if [ -z "$RESPONSE" ]; then
    echo "error=network_error"
    exit 0
fi

extract() {
    echo "$RESPONSE" | grep -i "^$1:" | head -1 | tr -d '\r' | sed 's/^[^:]*: *//'
}

h5_util=$(extract "anthropic-ratelimit-unified-5h-utilization")
h5_reset=$(extract "anthropic-ratelimit-unified-5h-reset")
d7_util=$(extract "anthropic-ratelimit-unified-7d-utilization")
d7_reset=$(extract "anthropic-ratelimit-unified-7d-reset")
status=$(extract "anthropic-ratelimit-unified-5h-status")

echo "h5_utilization=${h5_util:-0}"
echo "h5_reset=${h5_reset:-0}"
echo "d7_utilization=${d7_util:-0}"
echo "d7_reset=${d7_reset:-0}"
echo "status=${status:-unknown}"
echo "error=none"
