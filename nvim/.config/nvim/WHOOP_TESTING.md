# Whoop.nvim Plugin Testing Guide

## Setup

1. **Get Whoop API Credentials:**
   - Go to https://developer.whoop.com
   - Create an app to get your `Client ID` and `Client Secret`

2. **Set Environment Variables:**
   Add to your `~/.zshrc`:
   ```bash
   export WHOOP_CLIENT_ID="your_client_id"
   export WHOOP_CLIENT_SECRET="your_client_secret"
   ```
   
   Then reload: `source ~/.zshrc`

3. **Install Plugin:**
   Open Neovim and run:
   ```vim
   :Lazy sync
   ```

4. **Authenticate:**
   ```vim
   :WhoopAuth
   ```
   This will open your browser for OAuth authentication.

## Usage

- `:WhoopDashboard` - Open the main dashboard
- `:WhoopRefresh` - Force refresh all data
- `:WhoopAuth` - Re-authenticate
- `:WhoopConfig` - View configuration

## Key Mappings

- `<leader>wd` - Open dashboard
- `<leader>wr` - Refresh data
- `<leader>ws` - Sync/authenticate

## Troubleshooting

If you see "client_id and client_secret are required" error:
- Make sure environment variables are set
- Restart Neovim after setting them

If authentication fails:
- Check that your redirect URI in the Whoop Developer Console is: `http://localhost:8080/callback`
- Try running `:WhoopAuth` again
