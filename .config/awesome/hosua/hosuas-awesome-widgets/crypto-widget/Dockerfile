# ── Stage 1: build the React frontend ──────────────────────────────────────
FROM node:20-alpine AS frontend-build

RUN corepack enable && corepack prepare pnpm@10 --activate
# native addon build deps
RUN apk add --no-cache python3 make g++

WORKDIR /build
COPY web/package.json ./
# standalone install — no workspace needed inside Docker
RUN pnpm install
COPY web/ ./
RUN pnpm run build

# ── Stage 2: production deps only ───────────────────────────────────────────
FROM node:20-alpine AS deps-build

RUN corepack enable && corepack prepare pnpm@10 --activate
RUN apk add --no-cache python3 make g++

WORKDIR /build
COPY web/package.json ./
RUN pnpm install --prod

# ── Stage 3: lean runtime image ─────────────────────────────────────────────
FROM node:20-alpine

RUN corepack enable && corepack prepare pnpm@10 --activate
RUN apk add --no-cache nginx tini

WORKDIR /app

COPY web/server ./server
COPY --from=deps-build /build/node_modules ./node_modules
COPY web/package.json ./
COPY --from=frontend-build /build/dist ./dist

COPY nginx.conf /etc/nginx/http.d/default.conf
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

VOLUME ["/data"]
EXPOSE 8080 8081

ENTRYPOINT ["tini", "--"]
CMD ["docker-entrypoint.sh"]
