return {
  "nvim-tree/nvim-tree.lua",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    local nvimtree = require("nvim-tree")
    local api = vim.api
    local events = require("nvim-tree.events")
    local view = require("nvim-tree.view")

    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1

    vim.cmd([[ highlight NvimTreeFolderArrowClosed guifg=#3FC5FF ]])
    vim.cmd([[ highlight NvimTreeFolderArrowOpen guifg=#3FC5FF ]])

    -- nvim-tree setup
    nvimtree.setup({
      view = { adaptive_size = false, relativenumber = true },
      renderer = {
        indent_markers = { enable = true },
        icons = { glyphs = { folder = { arrow_closed = "", arrow_open = "" } } },
      },
      actions = { open_file = { window_picker = { enable = false } } },
      filters = { custom = { ".DS_Store" } },
      git = { ignore = false },
    })

    -- resize function
    local function resize_tree(delta)
      if view.is_visible() and view.get_winnr() == vim.api.nvim_get_current_win() then
        vim.cmd("NvimTreeResize " .. delta)
      end
    end

    -- enable buffer-local repeatable keys
    local function enable_resize_keys(bufnr)
      api.nvim_buf_set_keymap(bufnr, "n", "+", "", {
        callback = function() resize_tree("+5") end,
        noremap = true,
        silent = true,
      })
      api.nvim_buf_set_keymap(bufnr, "n", "_", "", {
        callback = function() resize_tree("-5") end,
        noremap = true,
        silent = true,
      })
    end

    -- leader keys to activate resize mode
    vim.keymap.set("n", "<leader>+", function()
      local bufnr = view.get_bufnr()
      if bufnr then enable_resize_keys(bufnr) end
    end, { desc = "Activate nvim-tree resize mode" })

    vim.keymap.set("n", "<leader>_", function()
      local bufnr = view.get_bufnr()
      if bufnr then enable_resize_keys(bufnr) end
    end, { desc = "Activate nvim-tree resize mode" })

    -- remove buffer-local keys when tree closes
    events.subscribe(events.Event.TreeClose, function()
      local bufnr = view.get_bufnr()
      if bufnr then
        pcall(api.nvim_buf_del_keymap, bufnr, "n", "+")
        pcall(api.nvim_buf_del_keymap, bufnr, "n", "_")
      end
    end)
  end,
}

