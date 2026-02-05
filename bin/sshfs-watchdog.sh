#!/bin/bash

# Enhanced SSHFS Watchdog Script with VPN Resilience
# Author: Enhanced for Tailscale + GlobalProtect compatibility
# Version: 2.0

set -euo pipefail

# Configuration
MOUNTPOINT="$HOME/homelab"
REMOTE="raspberrypi:/media/idohaber/storage"
LOG="$HOME/.sshfs-watchdog.log"
LOCKFILE="$HOME/.sshfs-watchdog.lock"
TIMEOUT=10
MAX_RETRIES=3
BACKOFF_INITIAL=5
BACKOFF_MAX=60

# SSHFS options optimized for VPN resilience
SSHFS_OPTIONS="-o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3,ConnectTimeout=10,volname=Homelab,auto_cache,no_readahead"

# Logging function
log() {
    local level="$1"
    shift
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$level] $*" >> "$LOG"
}

# Prevent concurrent runs
acquire_lock() {
    if [ -f "$LOCKFILE" ]; then
        local lock_age=$(($(date +%s) - $(stat -f %m "$LOCKFILE" 2>/dev/null || echo 0)))
        if [ "$lock_age" -lt 300 ]; then
            log "INFO" "Another instance is running (age: ${lock_age}s), skipping"
            exit 0
        else
            log "WARN" "Stale lock file found (age: ${lock_age}s), removing"
            rm -f "$LOCKFILE"
        fi
    fi
    echo $$ > "$LOCKFILE"
    trap 'rm -f "$LOCKFILE"' EXIT
}

# Network connectivity checks
check_tailscale_status() {
    if ! tailscale status >/dev/null 2>&1; then
        log "ERROR" "Tailscale is not running"
        return 1
    fi
    
    if ! ping -c 1 -W 5 raspberrypi >/dev/null 2>&1; then
        log "WARN" "Cannot ping raspberrypi via Tailscale"
        return 1
    fi
    
    return 0
}

check_ssh_connectivity() {
    local ssh_test=$(ssh -o ConnectTimeout="$TIMEOUT" -o BatchMode=yes -o StrictHostKeyChecking=no raspberrypi "echo 'SSH_OK'" 2>/dev/null || echo "SSH_FAILED")
    if [ "$ssh_test" = "SSH_OK" ]; then
        return 0
    else
        log "WARN" "SSH connectivity test failed"
        return 1
    fi
}

check_remote_path() {
    local path_exists=$(ssh -o ConnectTimeout="$TIMEOUT" -o BatchMode=yes raspberrypi "test -d '$(echo "$REMOTE" | cut -d: -f2)' && echo 'PATH_OK'" 2>/dev/null || echo "PATH_FAILED")
    if [ "$path_exists" = "PATH_OK" ]; then
        return 0
    else
        log "ERROR" "Remote path does not exist: $(echo "$REMOTE" | cut -d: -f2)"
        return 1
    fi
}

# Mount management
is_mounted() {
    mount | grep -q "$MOUNTPOINT"
}

is_mount_healthy() {
    if [ ! -d "$MOUNTPOINT" ]; then
        log "DEBUG" "Mount point directory does not exist"
        return 1
    fi
    
    # Check if it's actually mounted (not just an empty directory)
    local mount_check=$(mount | grep -c "$MOUNTPOINT" || echo "0")
    if [ "$mount_check" -eq 0 ]; then
        log "DEBUG" "Mount not found in mount table"
        return 1
    fi
    
    # Try to access the mount - this will fail if the mount is broken
    if ls "$MOUNTPOINT" >/dev/null 2>&1; then
        # Additional check: make sure it's not just empty
        local file_count=$(ls -A "$MOUNTPOINT" 2>/dev/null | wc -l | tr -d ' ')
        if [ "$file_count" -gt 0 ]; then
            log "DEBUG" "Mount health check passed ($file_count files visible)"
            return 0
        else
            log "WARN" "Mount directory exists but appears empty"
            return 1
        fi
    else
        log "DEBUG" "Cannot access mount directory"
        return 1
    fi
}

mount_sshfs() {
    local attempt=1
    local backoff=$BACKOFF_INITIAL
    
    while [ $attempt -le $MAX_RETRIES ]; do
        log "INFO" "Mount attempt $attempt/$MAX_RETRIES"
        
        # Pre-flight checks
        if ! check_tailscale_status; then
            log "ERROR" "Pre-flight: Tailscale check failed"
        elif ! check_ssh_connectivity; then
            log "ERROR" "Pre-flight: SSH check failed"
        elif ! check_remote_path; then
            log "ERROR" "Pre-flight: Remote path check failed"
        else
            # All checks passed, attempt mount
            if sshfs "$REMOTE" "$MOUNTPOINT" $SSHFS_OPTIONS 2>> "$LOG"; then
                log "INFO" "Mount successful"
                
                # Verify mount is working
                if is_mount_healthy; then
                    log "INFO" "Mount health check passed"
                    return 0
                else
                    log "ERROR" "Mount succeeded but health check failed"
                    diskutil unmount force "$MOUNTPOINT" >> "$LOG" 2>&1 || true
                fi
            else
                log "ERROR" "SSHFS mount command failed"
            fi
        fi
        
        if [ $attempt -lt $MAX_RETRIES ]; then
            log "INFO" "Waiting ${backoff}s before retry..."
            sleep "$backoff"
            backoff=$((backoff * 2))
            if [ $backoff -gt $BACKOFF_MAX ]; then
                backoff=$BACKOFF_MAX
            fi
        fi
        
        attempt=$((attempt + 1))
    done
    
    log "ERROR" "All $MAX_RETRIES mount attempts failed"
    return 1
}

unmount_sshfs() {
    log "INFO" "Unmounting $MOUNTPOINT"
    
    # Try graceful unmount first
    if diskutil unmount "$MOUNTPOINT" >> "$LOG" 2>&1; then
        log "INFO" "Graceful unmount successful"
        return 0
    fi
    
    # Force unmount if graceful failed
    if diskutil unmount force "$MOUNTPOINT" >> "$LOG" 2>&1; then
        log "INFO" "Force unmount successful"
        return 0
    fi
    
    # Fallback to umount command
    if umount "$MOUNTPOINT" >> "$LOG" 2>&1; then
        log "INFO" "umount command successful"
        return 0
    fi
    
    log "ERROR" "All unmount attempts failed"
    return 1
}

# Main logic
main() {
    acquire_lock
    
    log "INFO" "SSHFS watchdog started (PID: $$)"
    
    # Check mount point directory exists
    if [ ! -d "$MOUNTPOINT" ]; then
        log "INFO" "Creating mount point directory: $MOUNTPOINT"
        mkdir -p "$MOUNTPOINT"
    fi
    
    if is_mounted; then
        log "INFO" "Mount detected, checking health"
        
        if is_mount_healthy; then
            log "INFO" "Mount is healthy"
        else
            log "WARN" "Mount is broken, attempting remount"
            unmount_sshfs
            mount_sshfs
        fi
    else
        log "INFO" "No mount detected, attempting to mount"
        mount_sshfs
    fi
    
    log "INFO" "SSHFS watchdog completed"
}

# Health check mode for manual execution
if [ "${1:-}" = "--health" ]; then
    log "INFO" "=== HEALTH CHECK ==="
    echo "Tailscale Status:"
    if check_tailscale_status; then echo "  ✅ OK"; else echo "  ❌ FAILED"; fi
    
    echo "SSH Connectivity:"
    if check_ssh_connectivity; then echo "  ✅ OK"; else echo "  ❌ FAILED"; fi
    
    echo "Remote Path:"
    if check_remote_path; then echo "  ✅ OK"; else echo "  ❌ FAILED"; fi
    
    echo "Mount Status:"
    if is_mounted; then 
        if is_mount_healthy; then echo "  ✅ MOUNTED & HEALTHY"; else echo "  ❌ MOUNTED BUT BROKEN"; fi
    else echo "  ❌ NOT MOUNTED"; fi
    exit 0
fi

# Normal operation
main