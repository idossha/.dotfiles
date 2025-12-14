
return {
  "supermaven-inc/supermaven-nvim",
  config = function()
    local supermaven = require("supermaven-nvim")

    -- Setup Supermaven
    supermaven.setup({})

    -- Function to toggle Supermaven AI
    _G.toggle_supermaven = function()
      local api = require("supermaven-nvim.api")
      api.toggle()
    end

    -- Keymap to toggle (leader + a + s)
    vim.keymap.set("n", "<leader>as", _G.toggle_supermaven, { desc = "Toggle Supermaven AI" })
  end,
}

