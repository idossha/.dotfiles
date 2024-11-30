return {
  "stevearc/conform.nvim",
  lazy = true,
  event = { "BufReadPre", "BufNewFile" }, -- to disable, comment this out
  config = function()
    local conform = require("conform")

    -- Toggle state for formatting
    local formatting_enabled = true

    -- Function to toggle formatting
    function ToggleConformFormatting()
      formatting_enabled = not formatting_enabled
      if formatting_enabled then
        vim.cmd('echo "Conform formatting enabled"')
      else
        vim.cmd('echo "Conform formatting disabled"')
      end
    end

    -- Bind the toggle function to a key (e.g., <leader>tf)
    vim.api.nvim_set_keymap("n", "<leader>mt", ":lua ToggleConformFormatting()<CR>", { noremap = true, silent = true })

    -- Hook into Conform.nvim's setup
    conform.setup({
      formatters_by_ft = {
        javascript = { "prettier" },
        typescript = { "prettier" },
        javascriptreact = { "prettier" },
        typescriptreact = { "prettier" },
        svelte = { "prettier" },
        css = { "prettier" },
        html = { "prettier" },
        json = { "prettier" },
        yaml = { "prettier" },
        markdown = { "prettier" },
        graphql = { "prettier" },
        lua = { "stylua" },
        python = { "isort", "black" },
      },

      -- Uncomment this if you wish to have auto-formatting at save
      -- format_on_save = {
      --   lsp_fallback = true,
      --   async = false,
      --   timeout_ms = 1000,
      --   enable = function()
      --     return formatting_enabled
      --   end,
      -- },
    })

    vim.keymap.set({ "n", "v" }, "<leader>mp", function()
      conform.format({
        lsp_fallback = true,
        async = false,
        timeout_ms = 1000,
      })
    end, { desc = "Format file or range (in visual mode)" })
  end,
}
