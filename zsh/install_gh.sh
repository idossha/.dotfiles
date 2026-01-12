#!/bin/bash

# GitHub CLI Local Installation Script
# Installs GitHub CLI to ~/bin/ without requiring sudo

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

BIN_DIR="$HOME/bin"
[ ! -d "$BIN_DIR" ] && mkdir -p "$BIN_DIR"
[[ ":$PATH:" != *":$BIN_DIR:"* ]] && { export PATH="$BIN_DIR:$PATH"; echo "Add 'export PATH=\"$BIN_DIR:\$PATH\"' to your shell config"; }

# Detect operating system and architecture
OS=$(uname -s)
ARCH=$(uname -m)

case $OS in
    Linux)
        case $ARCH in
            x86_64)
                ARCH_SUFFIX="linux_amd64"
                EXT="tar.gz"
                ;;
            aarch64|arm64)
                ARCH_SUFFIX="linux_arm64"
                EXT="tar.gz"
                ;;
            *)
                print_error "Unsupported Linux architecture: $ARCH"
                exit 1
                ;;
        esac
        ;;
    Darwin)  # macOS
        case $ARCH in
            x86_64)
                ARCH_SUFFIX="macOS_amd64"
                EXT="zip"
                ;;
            arm64)
                ARCH_SUFFIX="macOS_arm64"
                EXT="zip"
                ;;
            *)
                print_error "Unsupported macOS architecture: $ARCH"
                exit 1
                ;;
        esac
        ;;
    *)
        print_error "Unsupported operating system: $OS"
        exit 1
        ;;
esac

print_status "Detected system: $OS $ARCH ($ARCH_SUFFIX)"

# Get latest release URL
print_status "Getting latest GitHub CLI release..."
DOWNLOAD_URL=$(curl -s https://api.github.com/repos/cli/cli/releases/latest | grep "browser_download_url.*${ARCH_SUFFIX}.${EXT}" | cut -d '"' -f 4)

if [ -z "$DOWNLOAD_URL" ]; then
    print_error "Could not get download URL"
    exit 1
fi

print_status "Downloading from: $DOWNLOAD_URL"

# Download and extract
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"
ARCHIVE_FILE="gh.${EXT}"
curl -sL -o "$ARCHIVE_FILE" "$DOWNLOAD_URL"
[ "$EXT" = "tar.gz" ] && tar -xzf "$ARCHIVE_FILE" || unzip -q "$ARCHIVE_FILE"

# Find and copy the binary
GH_DIR=$(find . -maxdepth 1 -type d -name "gh_*" | head -1)
if [ -z "$GH_DIR" ] && [ -f "./bin/gh" ]; then
    GH_DIR="."
fi

if [ -n "$GH_DIR" ] && [ -f "$GH_DIR/bin/gh" ]; then
    cp "$GH_DIR/bin/gh" "$BIN_DIR/"
    chmod +x "$BIN_DIR/gh"
    print_status "GitHub CLI installed to $BIN_DIR/gh"
else
    print_error "Could not find gh binary"
    exit 1
fi

# Clean up
cd /
rm -rf "$TEMP_DIR"

command -v gh &> /dev/null && gh --version &> /dev/null && print_status "GitHub CLI installed - run 'gh auth login'" || { print_error "Installation failed"; exit 1; }