#!/bin/bash
# toggle-credits.sh <true|false>
# Attempts to toggle usage credits via Claude.ai API.
# Falls back to opening the settings URL in the browser.

CREDS="$HOME/.claude/.credentials.json"
NEW_STATE="$1"

if [ -z "$NEW_STATE" ]; then
    xdg-open "https://claude.ai/settings/usage"
    exit 0
fi

TOKEN=$(python3 -c "
import json, sys
try:
    d = json.load(open('$CREDS'))
    print(d['claudeAiOauth']['accessToken'])
except:
    print('', end='')
" 2>/dev/null)

if [ -z "$TOKEN" ]; then
    xdg-open "https://claude.ai/settings/usage"
    exit 0
fi

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
    -X PATCH "https://claude.ai/api/account" \
    -H "Authorization: Bearer $TOKEN" \
    -H "content-type: application/json" \
    -d "{\"credits_enabled\":$NEW_STATE}" 2>/dev/null)

if [ "$HTTP_CODE" != "200" ]; then
    xdg-open "https://claude.ai/settings/usage"
fi
