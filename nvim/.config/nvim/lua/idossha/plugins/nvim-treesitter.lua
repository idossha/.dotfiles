return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",                -- keep parsers up to date
    dependencies = {
      "windwp/nvim-ts-autotag",        -- optional: auto-close HTML/JSX tags
      "JoosepAlviste/nvim-ts-context-commentstring", -- optional: context-aware commenting
    },
    config = function()
      local ts = require("nvim-treesitter")
      ts.setup({
        highlight = { enable = true },  -- enable syntax highlighting
        indent = { enable = true },     -- enable Treesitter-based indentation
        autotag = { enable = true },    -- auto-close tags if you installed nvim-ts-autotag
        ensure_installed = {            -- parsers to always install
          "json", "javascript", "typescript", "tsx", "html", "css",
          "lua", "python", "bash", "yaml", "markdown", "markdown_inline",
        },
        incremental_selection = {       -- optional, lightweight incremental selection
          enable = true,
          keymaps = {
            init_selection = "<C-space>",
            node_incremental = "<C-space>",
            node_decremental = "<bs>",
            scope_incremental = false,
          },
        },
      })

      -- optional: enable ts-context-commentstring for JSX/TSX files
      require("ts_context_commentstring").setup({})
    end,
  },
}

