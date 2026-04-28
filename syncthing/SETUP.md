# Syncthing: Mac ↔ Raspberry Pi Setup

## Architecture

- **Mac** — runs Syncthing via launchd
- **Pi** — runs Syncthing via systemd
- **Transport**: Tailscale VPN (TCP port 22000), falls back to LAN when on same network
- **Sync folder**: Mac `~/homelab` → Pi `/media/idohaber/storage` (one-way, Mac is source of truth)
- **Folder type**: Mac = `Send Only`, Pi = `Receive Only`

## Device IDs

Retrieve from each device's Syncthing web UI or config.xml. Not stored here.

## Mac Management

Use the control script:

```bash
syncthing-ctl.sh start|stop|restart|status|open|log
```

Plist: `~/Library/LaunchAgents/com.idohaber.syncthing.plist`
Log: `~/.syncthing.log`

## Pi Management

```bash
sudo systemctl start|stop|restart|status syncthing@<pi-user>
journalctl -u syncthing@<pi-user> -n 50 --no-pager
```

## Accessing the Pi Web UI

Syncthing only binds to `localhost:8384` — not reachable over Tailscale directly.
Use an SSH tunnel:

```bash
ssh -L 9384:localhost:8384 <pi-user>@<pi-tailscale-ip>
```

Then open **http://localhost:9384** in your browser.
(Port 9384 avoids conflict with the Mac's own Syncthing on 8384.)

---

## Troubleshooting Log

### Problem: Repeated `reading length: EOF` crash loop

**Symptom**: Mac log shows a connect/disconnect cycle every ~1 second:
```
INF Established secure connection (device=<PI_ID> ...)
INF New device connection (... remote.version=v1.29.5 ...)
INF Lost device connection (... error="reading length: EOF" ...)
```

**Root cause 1 — Version mismatch**: Mac had Syncthing `v2.0.14`, Pi had `v1.29.5`.
Syncthing v2 introduced a breaking wire protocol change incompatible with v1.x.

**Root cause 2 — Pi rejecting Mac**: After upgrading the Pi, its config didn't have
the Mac's device ID. Pi logs showed:
```
Connection rejected (device=<MAC_ID> address=<mac-tailscale-ip>:22000 ...)
```

### Fix: Upgrade Pi to v2.x

The `apt stable` channel lags behind — use the script in `bin/syncthing-upgrade-pi.sh`
to pull the latest `.deb` directly from GitHub releases:

```bash
scp ~/.dotfiles/bin/syncthing-upgrade-pi.sh <pi-user>@<pi-hostname>:~/
ssh <pi-user>@<pi-hostname> "sudo bash ~/syncthing_pi.sh"
```

### Fix: Add Mac device to Pi

1. SSH tunnel to Pi web UI: `ssh -L 9384:localhost:8384 <pi-user>@<pi-tailscale-ip>`
2. Open http://localhost:9384
3. Add Remote Device → paste Mac's device ID
4. Share the `storage` folder with the Mac device

### Fix: apt repo component name

If adding the official Syncthing apt repo, the correct component is `stable`, not `release`:

```bash
sudo curl -o /usr/share/keyrings/syncthing-archive-keyring.gpg \
  https://syncthing.net/release-key.gpg

echo "deb [signed-by=/usr/share/keyrings/syncthing-archive-keyring.gpg] \
https://apt.syncthing.net/ syncthing stable" | \
  sudo tee /etc/apt/sources.list.d/syncthing.list
```

Note: even with the correct repo, `stable` only provides v1.30.x as of early 2026.
Use `syncthing-upgrade-pi.sh` for v2.x.

### Problem: Pi syncing to wrong folder

**Symptom**: Syncthing reports 100% complete but files on the external drive are missing.

**Root cause**: Pi's folder was mapped to `~/storage` (`/home/<pi-user>/storage`) instead of
`/media/idohaber/storage` (the external drive). Syncthing was syncing to the wrong location.

**Fix**:
```bash
sudo systemctl stop syncthing@<pi-user>
touch /media/idohaber/storage/.stfolder
sed -i 's|path="~/storage"|path="/media/idohaber/storage"|' \
  /home/<pi-user>/.local/state/syncthing/config.xml
sudo systemctl start syncthing@<pi-user>
```

Pi config file location: `/home/<pi-user>/.local/state/syncthing/config.xml`

### Problem: Pi has junk folders in config

After install, Pi had two extra folders: `Default Folder` (`/home/<pi-user>/Sync`) and a blank
folder pointing to `~`. Remove them via the Pi web UI (SSH tunnel → http://localhost:9384).

### Setting sync direction (Send Only / Receive Only)

To make the Mac the sole source of truth and prevent the Pi from ever modifying or deleting
files on the Mac, set folder types via the REST API:

```bash
# On Mac — set to Send Only
APIKEY="<mac-api-key>"
curl -s -H "X-API-Key: $APIKEY" http://localhost:8384/rest/config/folders/btjrr-nt9wc \
  | python3 -c "import sys,json; d=json.load(sys.stdin); d['type']='sendonly'; print(json.dumps(d))" \
  | curl -X PUT -H "X-API-Key: $APIKEY" -H "Content-Type: application/json" \
      -d @- http://localhost:8384/rest/config/folders/btjrr-nt9wc

# On Pi — set to Receive Only
PI_APIKEY="<pi-api-key>"
curl -s -H "X-API-Key: $PI_APIKEY" http://localhost:8384/rest/config/folders/btjrr-nt9wc \
  | python3 -c "import sys,json; d=json.load(sys.stdin); d['type']='receiveonly'; print(json.dumps(d))" \
  | curl -X PUT -H "X-API-Key: $PI_APIKEY" -H "Content-Type: application/json" \
      -d @- http://localhost:8384/rest/config/folders/btjrr-nt9wc
```

Mac API key: `~/.syncthing.log` or `~/Library/Application Support/Syncthing/config.xml`
Pi API key: `/home/<pi-user>/.local/state/syncthing/config.xml`

**Behaviour with these settings:**

| Action | Result |
|--------|--------|
| Add/edit/delete on Mac | Synced to Pi |
| Add file directly on Pi | Ignored — local addition, Mac unaffected |
| Delete file on Pi | Mac ignores it; use "Revert Local Changes" in Pi web UI to restore |

### Verifying sync with API

```bash
# Check connection and sync state from Mac
APIKEY="<mac-api-key>"
curl -s -H "X-API-Key: $APIKEY" http://localhost:8384/rest/system/connections
curl -s -H "X-API-Key: $APIKEY" http://localhost:8384/rest/db/status?folder=btjrr-nt9wc

# Trigger a manual rescan on both sides
curl -s -X POST -H "X-API-Key: $APIKEY" http://localhost:8384/rest/db/scan?folder=btjrr-nt9wc
ssh <pi-user>@<pi-tailscale-ip> "curl -s -X POST -H 'X-API-Key: <pi-key>' http://localhost:8384/rest/db/scan?folder=btjrr-nt9wc"
```

### Testing sync

```bash
# Create a test file on Mac and verify it appears on Pi within ~15s
touch ~/homelab/.sync-test-$(date +%s)
sleep 15
ssh <pi-user>@<pi-tailscale-ip> "ls /media/idohaber/storage/.sync-test-*"
# Clean up
rm ~/homelab/.sync-test-*
```
