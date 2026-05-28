#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────────────────────
# crypto-widget uninstall.sh
#
# Stops and removes the crypto-widget systemd service and all installed files.
# Must be run as root (or via sudo).
#
# Usage:
#   sudo ./uninstall.sh           # remove everything
#   sudo ./uninstall.sh --keep-db # preserve crypto.db
# ─────────────────────────────────────────────────────────────────────────────

INSTALL_DIR="/usr/local/share/crypto-widget"
BIN_DIR="/usr/local/bin"
SERVICE_NAME="crypto-widget"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
KEEP_DB=false

[[ "${1:-}" == "--keep-db" ]] && KEEP_DB=true

# ── Colour helpers ───────────────────────────────────────────────────────────
red()   { printf '\033[31m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
blue()  { printf '\033[34m%s\033[0m\n' "$*"; }
bold()  { printf '\033[1m%s\033[0m\n'  "$*"; }

[[ $EUID -eq 0 ]] || { red "Error: run this script with sudo."; exit 1; }

bold "Uninstalling crypto-widget..."

# ── Stop + disable service ───────────────────────────────────────────────────
if systemctl list-unit-files "${SERVICE_NAME}.service" &>/dev/null; then
    if systemctl is-active --quiet "${SERVICE_NAME}" 2>/dev/null; then
        blue "Stopping ${SERVICE_NAME}..."
        systemctl stop "${SERVICE_NAME}"
    fi
    if systemctl is-enabled --quiet "${SERVICE_NAME}" 2>/dev/null; then
        systemctl disable "${SERVICE_NAME}"
    fi
    rm -f "${SERVICE_FILE}"
    systemctl daemon-reload
    green "✓ Systemd service removed"
fi

# ── Remove Docker container + image ─────────────────────────────────────────
if [[ -f "${INSTALL_DIR}/docker-compose.yml" ]]; then
    if docker compose version >/dev/null 2>&1; then
        COMPOSE="docker compose"
    elif command -v docker-compose >/dev/null 2>&1; then
        COMPOSE="docker-compose"
    fi
    blue "Removing Docker container and image..."
    cd "${INSTALL_DIR}"
    ${COMPOSE:-docker compose} down --rmi local --volumes 2>/dev/null || true
    green "✓ Docker resources removed"
fi

# ── Remove wrapper binary ────────────────────────────────────────────────────
rm -f "${BIN_DIR}/crypto-widget"

# ── Remove installed files ───────────────────────────────────────────────────
if [[ -d "${INSTALL_DIR}" ]]; then
    if [[ "${KEEP_DB}" == "true" ]]; then
        blue "Preserving crypto.db (--keep-db)"
        cp "${INSTALL_DIR}/crypto.db" /tmp/crypto-widget-backup.db 2>/dev/null || true
    fi
    rm -rf "${INSTALL_DIR}"
    green "✓ Files removed from ${INSTALL_DIR}"
fi

echo ""
green "✓ crypto-widget uninstalled"
if [[ "${KEEP_DB}" == "true" ]]; then
    bold "  Database backed up to: /tmp/crypto-widget-backup.db"
fi
