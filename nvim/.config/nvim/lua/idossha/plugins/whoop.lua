return {
  "idossha/whoop.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
  },
  config = function()
    -- Get credentials from environment variables
    local client_id = os.getenv("WHOOP_CLIENT_ID")
    local client_secret = os.getenv("WHOOP_CLIENT_SECRET")
    
    if not client_id or not client_secret then
      vim.notify("whoop.nvim: Set WHOOP_CLIENT_ID and WHOOP_CLIENT_SECRET environment variables", vim.log.levels.WARN)
      return
    end
    
    require("whoop").setup({
      client_id = client_id,
      client_secret = client_secret,
      refresh_interval = 3600,
      auto_refresh = true,
      theme = "auto",
      show_trends = true,
      default_days = 7,
      mappings = {
        dashboard = "<leader>wd",
        refresh = "<leader>wr",
        sync = "<leader>ws"
      }
    })
  end,
  lazy = false, -- Load immediately for testing
}
