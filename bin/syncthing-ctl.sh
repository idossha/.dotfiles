#!/bin/bash

# Syncthing control script for macOS
# Manages the Syncthing launchd service and provides quick access to common operations

PLIST_LABEL="com.idohaber.syncthing"
PLIST_PATH="$HOME/Library/LaunchAgents/$PLIST_LABEL.plist"
WEB_UI="http://localhost:8384"
LOG_FILE="$HOME/.syncthing.log"

usage() {
    echo "Usage: syncthing-ctl {start|stop|restart|status|open|log|setup-pi}"
    echo ""
    echo "Commands:"
    echo "  start      Start Syncthing via launchd"
    echo "  stop       Stop Syncthing via launchd"
    echo "  restart    Restart Syncthing"
    echo "  status     Show whether Syncthing is running and sync state"
    echo "  open       Open the Syncthing web UI in the default browser"
    echo "  log        Tail the Syncthing log"
    echo "  setup-pi   Print Raspberry Pi setup instructions"
}

check_plist() {
    if [ ! -f "$PLIST_PATH" ]; then
        echo "Error: Plist not found at $PLIST_PATH"
        echo "Run 'stow syncthing' from your dotfiles directory first."
        exit 1
    fi
}

cmd_start() {
    check_plist
    if launchctl list | grep -q "$PLIST_LABEL"; then
        echo "Syncthing is already loaded."
    else
        launchctl load "$PLIST_PATH"
        echo "Syncthing started."
    fi
}

cmd_stop() {
    if launchctl list | grep -q "$PLIST_LABEL"; then
        launchctl unload "$PLIST_PATH"
        echo "Syncthing stopped."
    else
        echo "Syncthing is not running."
    fi
}

cmd_restart() {
    cmd_stop
    sleep 1
    cmd_start
}

cmd_status() {
    echo "=== Syncthing Status ==="
    if launchctl list | grep -q "$PLIST_LABEL"; then
        local pid
        pid=$(launchctl list | grep "$PLIST_LABEL" | awk '{print $1}')
        echo "Service: running (PID: $pid)"
    else
        echo "Service: not running"
    fi

    # Check if the web UI is reachable
    if curl -s -o /dev/null -w "%{http_code}" "$WEB_UI" 2>/dev/null | grep -q "200\|302"; then
        echo "Web UI: reachable at $WEB_UI"
    else
        echo "Web UI: not reachable"
    fi

    # Show device ID for sharing with Pi
    if command -v syncthing &>/dev/null; then
        echo ""
        echo "Device ID (share this with your Pi):"
        syncthing --device-id 2>/dev/null || echo "  (start Syncthing first to generate device ID)"
    fi
}

cmd_open() {
    echo "Opening Syncthing web UI..."
    open "$WEB_UI"
}

cmd_log() {
    if [ -f "$LOG_FILE" ]; then
        tail -f "$LOG_FILE"
    else
        echo "No log file found at $LOG_FILE"
        echo "Start Syncthing first."
    fi
}

cmd_setup_pi() {
    cat <<'INSTRUCTIONS'
=== Raspberry Pi Syncthing Setup ===

1. Install Syncthing on the Pi:
   sudo apt update && sudo apt install -y syncthing

2. Enable and start the Syncthing service:
   sudo systemctl enable syncthing@idohaber
   sudo systemctl start syncthing@idohaber

3. Access the Pi's Syncthing web UI:
   - From the Pi: http://localhost:8384
   - From Mac (via Tailscale): http://<pi-tailscale-ip>:8384

4. On the Pi's web UI:
   a. Go to Actions > Show ID, copy the device ID
   b. On your Mac's web UI (http://localhost:8384), click "Add Remote Device"
   c. Paste the Pi's device ID
   d. Use the Pi's Tailscale IP as the address: tcp://<pi-tailscale-ip>:22000

5. Share a folder:
   a. On the Pi's web UI, click "Add Folder"
   b. Set the folder path to: /media/idohaber/storage
   c. Share it with your Mac device
   d. On the Mac, accept the folder and set local path to: ~/homelab

6. Recommended: Set the folder type on the Pi to "Send & Receive"
   and on the Mac to "Send & Receive" for bidirectional sync.

Tips:
- Use Tailscale IPs (not DNS names) for VPN resilience
- Find your Tailscale IPs with: tailscale ip -4
- Syncthing will automatically reconnect when network changes
INSTRUCTIONS
}

# Main
case "${1:-}" in
    start)      cmd_start ;;
    stop)       cmd_stop ;;
    restart)    cmd_restart ;;
    status)     cmd_status ;;
    open)       cmd_open ;;
    log)        cmd_log ;;
    setup-pi)   cmd_setup_pi ;;
    *)          usage; exit 1 ;;
esac
