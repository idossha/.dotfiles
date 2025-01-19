return {
  "barrett-ruth/live-server.nvim",
  -- build = "pnpm add -g live-server",  -- or "npm install -g live-server"
  build = "npm install -g live-server",  -- or "npm install -g live-server"
  cmd = { "LiveServerStart", "LiveServerStop" },
  config = function()
    -- This will run the default setup for live-server.nvim.
    -- (Check the plugin's docs if you want to pass custom config options.)
    require("live-server").setup()


  end
}

