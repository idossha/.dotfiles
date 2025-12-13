
return {
  "supermaven-inc/supermaven-nvim",
  config = function()
    local supermaven = require("supermaven-nvim")

    -- State variable to track on/off
    local sm_enabled = true

    -- Function to toggle Supermaven AI
    _G.toggle_supermaven = function()
      sm_enabled = not sm_enabled
      if sm_enabled then
        print("Supermaven: ON")
      else
        print("Supermaven: OFF")
      end
    end

    -- Keymap to toggle (leader + a + s)
    vim.keymap.set("n", "<leader>as", _G.toggle_supermaven, { desc = "Toggle Supermaven AI" })

    -- Setup Supermaven with a wrapper to respect toggle
    supermaven.setup({
      on_attach = function(client, bufnr)
        -- Optional: you can wrap completion or suggestions here if needed
      end,
      enabled = function()
        return sm_enabled
      end,
    })
  end,
}

