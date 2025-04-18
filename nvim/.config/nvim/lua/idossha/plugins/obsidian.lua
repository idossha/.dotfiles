-- obsidian.nvim plugin configuration
-- This goes in your plugins directory
return {
  "epwalsh/obsidian.nvim",
  dependencies = { 
    "nvim-lua/plenary.nvim",
  },
  version = "*",
  lazy = true,
  ft = "markdown",
  cmd = {
    "ObsidianOpen", 
    "ObsidianQuickSwitch", 
    "ObsidianNew", 
    "ObsidianTemplate", 
    "ObsidianNewFromTemplate", 
    "ObsidianSearch",
    "ObsidianPasteImg"
  },
  config = function()
    local obsidian = require("obsidian")
    obsidian.setup({
      -- Your Obsidian vault path
      dir = "/Users/idohaber/Silicon_Mind",
      
      -- Disable frontmatter management
      disable_frontmatter = true,
      
      -- Template configuration
      templates = {
        folder = "Templates",
        date_format = "%Y%m%d",
        time_format = "%H%M",
        substitutions = {},
      },
      
      -- Enable nvim-cmp completion
      completion = {
        nvim_cmp = true,
      },

      ui = {
        enable = true, -- keep general ui features
        checkboxes =  {}, -- specifically disable checkboxes

      },  
      -- Simple title-based note naming (no dates)
      note_id_func = function(title)
        if title and title ~= "" then
          -- Simply convert spaces to hyphens
          return title:gsub(" ", "-")
        else
          -- Fallback if no title
          return "untitled-note"
        end
      end,
      
      -- Basic mappings
      mappings = {
        -- Smart link handling
        ["gf"] = {
          action = function()
            return require("obsidian").util.gf_passthrough()
          end,
          opts = { noremap = false, expr = true, buffer = true },
        },
      },
    })
    
    -- Create keybindings for Markdown files only
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "markdown",
      callback = function()
        local bufnr = vim.api.nvim_get_current_buf()
        
        -- Check if the current file is in the Obsidian vault
        local current_file = vim.fn.expand('%:p')
        local in_vault = string.find(current_file, "/Users/idohaber/Silicon_Mind") ~= nil
        
        -- Only set obsidian keybindings if we're in the vault
        if in_vault then
          -- Link navigation
          vim.keymap.set("n", "gf", function()
            return obsidian.util.gf_passthrough()
          end, { buffer = bufnr, noremap = false, expr = true, desc = "Obsidian: Follow link" })
          
          -- Open current file in Obsidian GUI
          vim.keymap.set("n", "<leader>oo", ":ObsidianOpen<CR>", 
            { buffer = bufnr, desc = "Open in Obsidian" })
        end
        
        -- Add conceallevel setting for Obsidian syntax features
        vim.opt_local.conceallevel = 1
      end,
    })
  end,
}
