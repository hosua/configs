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

# Try to fetch credits/billing info from Claude.ai
BILLING=$(curl -s "https://claude.ai/api/account" \
    -H "Authorization: Bearer $TOKEN" \
    -H "content-type: application/json" 2>/dev/null)

echo "$BILLING" | python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
    def find(obj, *keys):
        for k in keys:
            if isinstance(obj, dict) and k in obj:
                return obj[k]
        return None
    balance = find(d, 'credits_balance', 'balance', 'credit_balance')
    limit   = find(d, 'monthly_limit', 'spend_limit', 'monthly_spend_limit')
    enabled = find(d, 'credits_enabled', 'usage_credits_enabled')
    try:    print('balance={:.2f}'.format(float(balance))) if balance is not None else print('balance=N/A')
    except: print('balance=N/A')
    try:    print('monthly_limit={:.2f}'.format(float(limit))) if limit is not None else print('monthly_limit=N/A')
    except: print('monthly_limit=N/A')
    if enabled is not None:
        print('credits_enabled=' + ('true' if enabled else 'false'))
    else:
        print('credits_enabled=unknown')
except:
    print('balance=N/A')
    print('monthly_limit=N/A')
    print('credits_enabled=unknown')
" 2>/dev/null || {
    echo "balance=N/A"
    echo "monthly_limit=N/A"
    echo "credits_enabled=unknown"
}
