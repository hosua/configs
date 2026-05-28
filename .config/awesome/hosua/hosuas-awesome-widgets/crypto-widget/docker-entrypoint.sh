#!/bin/sh
set -e

# Ensure nginx log dirs exist (Alpine doesn't create them)
mkdir -p /var/log/nginx /var/lib/nginx/tmp

# Start nginx (frontend on :8080, proxies /api → :8081)
nginx -g "daemon off;" &

# Start Hono API server on :8081
exec node_modules/.bin/tsx server/index.ts
