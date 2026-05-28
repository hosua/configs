#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────────────────────
# crypto-widget install.sh
#
# Installs the crypto-widget dashboard as a systemd service.
# Must be run as root (or via sudo).
#
# Usage:
#   sudo ./install.sh                    # install from current directory
#   sudo ./install.sh /path/to/source    # install from explicit source
# ─────────────────────────────────────────────────────────────────────────────

INSTALL_DIR="/usr/local/share/crypto-widget"
BIN_DIR="/usr/local/bin"
SERVICE_NAME="crypto-widget"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
SOURCE_DIR="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"

# ── Colour helpers ───────────────────────────────────────────────────────────
red()   { printf '\033[31m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
blue()  { printf '\033[34m%s\033[0m\n' "$*"; }
bold()  { printf '\033[1m%s\033[0m\n'  "$*"; }

# ── Preflight checks ─────────────────────────────────────────────────────────
[[ $EUID -eq 0 ]] || { red "Error: run this script with sudo."; exit 1; }

for cmd in docker systemctl rsync pnpm; do
    command -v "$cmd" >/dev/null 2>&1 || {
        red "Error: '$cmd' is required but not installed."
        exit 1
    }
done

# docker compose (v2 plugin) or docker-compose (v1)
if docker compose version >/dev/null 2>&1; then
    COMPOSE="docker compose"
elif command -v docker-compose >/dev/null 2>&1; then
    COMPOSE="docker-compose"
else
    red "Error: Docker Compose is required (docker compose or docker-compose)."
    exit 1
fi

bold "Installing crypto-widget..."
blue "  Source : ${SOURCE_DIR}"
blue "  Target : ${INSTALL_DIR}"

# ── Copy files ───────────────────────────────────────────────────────────────
mkdir -p "${INSTALL_DIR}"
rsync -a --delete \
    --exclude='.git' \
    --exclude='node_modules' \
    --exclude='web/node_modules' \
    --exclude='web/dist' \
    --exclude='cache/' \
    --exclude='*.db-shm' \
    --exclude='*.db-wal' \
    "${SOURCE_DIR}/" "${INSTALL_DIR}/"

# Keep the live DB and data dir in-place; create if missing
mkdir -p "${INSTALL_DIR}/data"
[[ -f "${SOURCE_DIR}/crypto.db" ]] && \
    cp -n "${SOURCE_DIR}/crypto.db" "${INSTALL_DIR}/crypto.db" 2>/dev/null || true

# ── Build Docker image ───────────────────────────────────────────────────────
blue "Building Docker image (this may take a minute)..."
cd "${INSTALL_DIR}"
$COMPOSE build

# ── Convenience wrapper scripts ──────────────────────────────────────────────
cat > "${BIN_DIR}/crypto-widget" << 'EOF'
#!/usr/bin/env bash
INSTALL_DIR="/usr/local/share/crypto-widget"
case "${1:-}" in
    start)   systemctl start  crypto-widget ;;
    stop)    systemctl stop   crypto-widget ;;
    restart) systemctl restart crypto-widget ;;
    status)  systemctl status  crypto-widget ;;
    logs)    journalctl -u crypto-widget -f ;;
    update)
        cd "$INSTALL_DIR"
        docker compose pull 2>/dev/null || docker compose build
        systemctl restart crypto-widget
        ;;
    *)
        echo "Usage: crypto-widget {start|stop|restart|status|logs|update}"
        ;;
esac
EOF
chmod +x "${BIN_DIR}/crypto-widget"

# ── Systemd service ──────────────────────────────────────────────────────────
cat > "${SERVICE_FILE}" << EOF
[Unit]
Description=Crypto Widget Dashboard
Documentation=https://github.com/hosua/hosuas-awesome-widgets
After=network-online.target docker.service
Wants=network-online.target
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=${INSTALL_DIR}
ExecStartPre=${COMPOSE} pull --ignore-buildable 2>/dev/null || true
ExecStart=${COMPOSE} up -d --remove-orphans
ExecStop=${COMPOSE} down
ExecReload=${COMPOSE} up -d --remove-orphans
TimeoutStartSec=120
TimeoutStopSec=30

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now "${SERVICE_NAME}"

# ── Done ─────────────────────────────────────────────────────────────────────
echo ""
green "✓ crypto-widget installed and running"
echo ""
bold "  Endpoints:"
echo "    Frontend : http://localhost:42069"
echo "    API      : http://localhost:42070"
echo ""
bold "  Manage:"
echo "    systemctl {start|stop|restart|status} ${SERVICE_NAME}"
echo "    journalctl -u ${SERVICE_NAME} -f"
echo "    crypto-widget {start|stop|restart|status|logs|update}"
echo ""
bold "  The widget Lua script writes live data to:"
echo "    ${INSTALL_DIR}/data/latest.json"
echo "  Make sure AWESOME_DATA_DIR points there, or symlink:"
echo "    ln -sf ${SOURCE_DIR}/data ${INSTALL_DIR}/data"
