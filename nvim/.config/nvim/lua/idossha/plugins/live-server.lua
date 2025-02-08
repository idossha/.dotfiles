return {
  "barrett-ruth/live-server.nvim",
  build = "npm install -g live-server",  -- or "npm install -g live-server"
  cmd = { "LiveServerStart", "LiveServerStop" },
  
  config = function()
    require("live-server").setup()
  end
}

