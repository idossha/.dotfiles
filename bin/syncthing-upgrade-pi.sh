#!/bin/bash

# syncthing-upgrade-pi.sh
# Run this on the Raspberry Pi to install/upgrade Syncthing to the latest v2.x
# from GitHub releases (bypasses the outdated apt stable channel).

set -euo pipefail

GITHUB_API="https://api.github.com/repos/syncthing/syncthing/releases/latest"
INSTALL_DIR="/usr/bin"
SERVICE_USER="${SUDO_USER:-${USER}}"
TMPDIR_WORK=$(mktemp -d)

cleanup() {
    rm -rf "$TMPDIR_WORK"
}
trap cleanup EXIT

log()  { echo "[syncthing-upgrade] $*" >&2; }
die()  { echo "[syncthing-upgrade] ERROR: $*" >&2; exit 1; }

require_root() {
    [ "$(id -u)" -eq 0 ] || die "Run this script with sudo: sudo $0"
}

detect_arch() {
    local machine
    machine=$(uname -m)
    case "$machine" in
        aarch64|arm64) echo "arm64" ;;
        armv7l|armhf)  echo "arm"   ;;
        x86_64)        echo "amd64" ;;
        *)             die "Unsupported architecture: $machine" ;;
    esac
}

get_download_url() {
    local arch="$1"
    local url

    log "Fetching latest release info from GitHub..."
    # Prefer the .deb package (cleaner install on Debian/Raspberry Pi OS)
    url=$(curl -fsSL "$GITHUB_API" \
        | grep "browser_download_url" \
        | grep -o 'https://[^"]*' \
        | grep "syncthing_.*_${arch}\\.deb$" \
        | head -1)

    [ -n "$url" ] || die "Could not find .deb download URL for ${arch}."
    echo "$url"
}

stop_service() {
    log "Stopping Syncthing service for user '$SERVICE_USER'..."
    if systemctl is-active --quiet "syncthing@${SERVICE_USER}"; then
        systemctl stop "syncthing@${SERVICE_USER}"
        log "Service stopped."
    else
        log "Service was not running, continuing."
    fi
}

start_service() {
    log "Starting Syncthing service for user '$SERVICE_USER'..."
    systemctl daemon-reload
    systemctl enable "syncthing@${SERVICE_USER}" 2>/dev/null || true
    systemctl start "syncthing@${SERVICE_USER}"
    log "Service started."
}

install_deb() {
    local url="$1"
    local deb="${TMPDIR_WORK}/syncthing.deb"

    log "Downloading: $url"
    curl -fsSL "$url" -o "$deb"

    log "Installing .deb package..."
    dpkg -i "$deb"
}

main() {
    require_root

    local arch
    arch=$(detect_arch)
    log "Detected architecture: $arch"

    local current_version=""
    if command -v syncthing &>/dev/null; then
        current_version=$(syncthing --version 2>/dev/null | awk '{print $2}' || echo "unknown")
        log "Current version: $current_version"
    else
        log "Syncthing not currently installed."
    fi

    local url
    url=$(get_download_url "$arch")

    local new_version
    new_version=$(echo "$url" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+')
    log "Target version:  $new_version"

    if [ "$current_version" = "$new_version" ]; then
        log "Already on $new_version — nothing to do."
        exit 0
    fi

    stop_service
    install_deb "$url"
    start_service

    local installed_version
    installed_version=$(syncthing --version 2>/dev/null | awk '{print $2}')
    log ""
    log "Upgrade complete: $current_version -> $installed_version"
    log ""
    log "Device ID:"
    syncthing device-id 2>/dev/null || log "  (start service first to generate device ID)"
    log ""
    log "Service status:"
    systemctl status "syncthing@${SERVICE_USER}" --no-pager -l | tail -5
}

main "$@"
