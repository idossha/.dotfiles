
return {
  "epwalsh/obsidian.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  version = "*",  -- recommended: use latest release instead of latest commit
  lazy = true,
  ft = "markdown",
  config = function()
    local obsidian = require("obsidian")
    obsidian.setup({
      -- Replace with the path to your Obsidian vault.
      dir = "/Users/idohaber/Silicon_Mind",  -- remove trailing slash if necessary
      templates = {  -- use "templates" (plural) here
        folder = "Templates",  -- must exactly match your folder name in the vault
        date_format = "%Y-%m-%d",
        time_format = "%H:%M",
        substitutions = {},
      },
      completion = {
        nvim_cmp = true,
      },
      note_id_func = function(title)
        local date = vim.fn.strftime("%Y-%m-%d")
        if title and title ~= "" then
          return date .. "-" .. title:gsub(" ", "-")
        else
          return date
        end
      end,
      mappings = {
        -- Overrides the 'gf' mapping to work on markdown/wiki links within your vault.
        ["gf"] = {
          action = function()
            return require("obsidian").util.gf_passthrough()
          end,
          opts = { noremap = false, expr = true, buffer = true },
        },
        -- Remove the default <CR> mapping and assign the smart action to <leader>oc
        ["<leader>os"] = {
          action = function()
            return require("obsidian").util.smart_action()
          end,
          opts = { buffer = true, expr = true, desc = "Obsidian: Smart Action" },
        },
      },
    })

    -- Create an autocommand for Markdown filetypes to set keybindings for additional commands
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "markdown",
      callback = function()
        local bufnr = vim.api.nvim_get_current_buf()

        -- Mapping for gf: call gf_passthrough()
        vim.keymap.set("n", "gf", function()
          return obsidian.util.gf_passthrough()
        end, { buffer = bufnr, noremap = false, expr = true, desc = "Obsidian: gf passthrough" })

        -- Additional built-in Obsidian commands:
        vim.keymap.set("n", "<leader>oo", "<cmd>ObsidianOpen<CR>", { buffer = bufnr, desc = "Obsidian: Open Note" })
        vim.keymap.set("n", "<leader>oq", "<cmd>ObsidianQuickSwitch<CR>", { buffer = bufnr, desc = "Obsidian: Quick Switch" })
        vim.keymap.set("n", "<leader>oT", "<cmd>ObsidianTemplate<CR>", { buffer = bufnr, desc = "Obsidian: fill in template" })
        vim.keymap.set("n", "<leader>ot", "<cmd>ObsidianNewFromTemplate<CR>", { buffer = bufnr, desc = "Obsidian: New from Template" })
        vim.keymap.set("n", "<leader>oi", "<cmd>ObsidianPasteImg<CR>", { buffer = bufnr, desc = "Obsidian: Paste Image" })
      end,
    })
  end,
}

