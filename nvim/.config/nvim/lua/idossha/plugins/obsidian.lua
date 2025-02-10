
return {
  "epwalsh/obsidian.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },

  config = function()
    require("obsidian").setup({
      -- Replace with the path to your Obsidian vault
      dir = "/Users/idohaber/Desktop/Silicon_Mind/",
      completion = {
        nvim_cmp = true,
      },
      note_id_func = function(title)
        local suffix = title and title:gsub(" ", "-") or ""
        return vim.fn.strftime("%Y-%m-%d") .. suffix
      end,
    })
  end,
}

