-- https://github.com/stevearc/conform.nvim
-- Formatting plugin for Neovim that supports LSP
-- extend the functinoality and also adds key bindings with toggle

-- We build a table that is both a plugin spec for lazy.nvim
-- and a Lua module so we can call functions like `.toggle_formatting()`.

local M = {
  "stevearc/conform.nvim",
  lazy = true,
  event = { "BufReadPre", "BufNewFile" },
}

-- Local state
M.formatting_enabled = true

-- Toggle function
function M.toggle_formatting()
  M.formatting_enabled = not M.formatting_enabled
  if M.formatting_enabled then
    vim.notify("Conform formatting enabled", vim.log.levels.INFO)
  else
    vim.notify("Conform formatting disabled", vim.log.levels.WARN)
  end
end

-- Plugin config
function M.config()
  local conform = require("conform")

  conform.setup({
    -- List of formatters by filetype
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

    -- Auto-format on save (respects toggle via <leader>Ft)
    format_on_save = function(bufnr)
      if not M.formatting_enabled then
        return
      end
      return {
        lsp_fallback = true,
        async = false,
        timeout_ms = 1000,
      }
    end,
  })
end

return M

