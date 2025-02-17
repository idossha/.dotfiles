-- set leader key to space
vim.g.mapleader = " "

local keymap = vim.keymap -- for conciseness

---------------------
-- General Keymaps -------------------

-- use jk to exit insert mode
keymap.set("i", "jk", "<ESC>", { desc = "Exit insert mode with jk" })

-- clear search highlights
keymap.set("n", "<leader>nh", ":nohl<CR>", { desc = "Clear search highlights" })

-- increment/decrement numbers
keymap.set("n", "<leader>+", "<C-a>", { desc = "Increment number" }) -- increment
keymap.set("n", "<leader>-", "<C-x>", { desc = "Decrement number" }) -- decrement

-- window management
keymap.set("n", "<leader>sv", "<C-w>v", { desc = "Split window vertically" }) -- split window vertically
keymap.set("n", "<leader>sh", "<C-w>s", { desc = "Split window horizontally" }) -- split window horizontally
keymap.set("n", "<leader>se", "<C-w>=", { desc = "Make splits equal size" }) -- make split windows equal width & height
keymap.set("n", "<leader>sx", "<cmd>close<CR>", { desc = "Close current split" }) -- close current split window

-- tab management
keymap.set("n", "<leader>to", "<cmd>tabnew<CR>", { desc = "Open new tab" }) -- open new tab
keymap.set("n", "<leader>tx", "<cmd>tabclose<CR>", { desc = "Close current tab" }) -- close current tab
keymap.set("n", "<leader>tn", "<cmd>tabn<CR>", { desc = "Go to next tab" }) --  go to next tab
keymap.set("n", "<leader>tp", "<cmd>tabp<CR>", { desc = "Go to previous tab" }) --  go to previous tab
keymap.set("n", "<leader>tf", "<cmd>tabnew %<CR>", { desc = "Open current buffer in new tab" }) --  move current buffer to new tab

-- live server
keymap.set("n", "<leader>LS", "<cmd>LiveServerStart<CR>", { desc = "Start Live Server" })
keymap.set("n", "<leader>LE", "<cmd>LiveServerStop<CR>",  { desc = "Stop Live Server" })

-- harpoon
keymap.set("n", "<leader>hr", "<cmd>lua require('harpoon.mark').rm_file()<cr>", { desc = "Remove harpoon mark" })
keymap.set("n", "<leader>h1", "<cmd>lua require('harpoon.ui').nav_file(1)<cr>", { desc = "Go to harpoon mark 1" })
keymap.set("n", "<leader>h2", "<cmd>lua require('harpoon.ui').nav_file(2)<cr>", { desc = "Go to harpoon mark 2" })
keymap.set("n", "<leader>h3", "<cmd>lua require('harpoon.ui').nav_file(3)<cr>", { desc = "Go to harpoon mark 3" })
keymap.set("n", "<leader>h4", "<cmd>lua require('harpoon.ui').nav_file(4)<cr>", { desc = "Go to harpoon mark 4" })
keymap.set("n","<leader>hm", "<cmd>lua require('harpoon.mark').add_file()<cr>",{ desc = "Mark file with harpoon" })
keymap.set("n", "<leader>hn", "<cmd>lua require('harpoon.ui').nav_next()<cr>", { desc = "Go to next harpoon mark" })
keymap.set("n","<leader>hp", "<cmd>lua require('harpoon.ui').nav_prev()<cr>",{ desc = "Go to previous harpoon mark" })
keymap.set("n","<leader>hh", "<cmd>lua require('harpoon.ui').toggle_quick_menu()<cr>",{ desc = "Harpoon quick menu" })

-- Markdown Preview Toggle
keymap.set("n", "<leader>Mp", "<cmd>MarkdownPreviewToggle<CR>", {
  desc = "Toggle Markdown Preview",
})

-- nvim-tree
keymap.set("n", "<leader>ee", "<cmd>NvimTreeToggle<CR>", { desc = "Toggle file explorer" }) -- toggle file explorer
keymap.set("n", "<leader>ef", "<cmd>NvimTreeFindFileToggle<CR>", { desc = "Toggle file explorer on current file" }) -- toggle file explorer on current file
keymap.set("n", "<leader>ec", "<cmd>NvimTreeCollapse<CR>", { desc = "Collapse file explorer" }) -- collapse file explorer
keymap.set("n", "<leader>er", "<cmd>NvimTreeRefresh<CR>", { desc = "Refresh file explorer" }) -- refresh file explorer

-- telescope.lua:
keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "Fuzzy find files in cwd" })
keymap.set("n", "<leader>fr", "<cmd>Telescope oldfiles<cr>", { desc = "Fuzzy find recent files" })
keymap.set("n", "<leader>fs", "<cmd>Telescope live_grep<cr>", { desc = "Find string in cwd" })
keymap.set("n", "<leader>fc", "<cmd>Telescope grep_string<cr>", { desc = "Find string under cursor in cwd" })

-- auto-session.lua:
keymap.set("n", "<leader>wr", "<cmd>SessionRestore<CR>", { desc = "Restore session for cwd" }) -- restore last workspace session for current directory
keymap.set("n", "<leader>ws", "<cmd>SessionSave<CR>", { desc = "Save session for auto session root dir" }) -- save workspace session for current working directory

----------------------------------------------------------------------
--- Snacks
----------------------------------------------------------------------

-- Zen / Zoom
keymap.set("n", "<leader>z", function() Snacks.zen() end, { desc = "Toggle Zen Mode" })
keymap.set("n", "<leader>Z", function() Snacks.zen.zoom() end, { desc = "Toggle Zoom" })

-- Scratch Buffer
keymap.set("n", "<leader>.", function() Snacks.scratch() end, { desc = "Toggle Scratch Buffer" })
keymap.set("n", "<leader>S", function() Snacks.scratch.select() end, { desc = "Select Scratch Buffer" })

-- Notifications
keymap.set("n", "<leader>n", function() Snacks.notifier.show_history() end, { desc = "Notification History" })
keymap.set("n", "<leader>un", function() Snacks.notifier.hide() end, { desc = "Dismiss All Notifications" })

-- Buffers
keymap.set("n", "<leader>bd", function() Snacks.bufdelete() end, { desc = "Delete Buffer" })

-- Rename file
keymap.set("n", "<leader>cR", function() Snacks.rename.rename_file() end, { desc = "Rename File" })

-- Git / LazyGit
keymap.set({ "n", "v" }, "<leader>gB", function() Snacks.gitbrowse() end, { desc = "Git Browse" })
keymap.set("n", "<leader>gb", function() Snacks.git.blame_line() end, { desc = "Git Blame Line" })
keymap.set("n", "<leader>gf", function() Snacks.lazygit.log_file() end, { desc = "Lazygit Current File History" })
keymap.set("n", "<leader>gg", function() Snacks.lazygit() end, { desc = "Lazygit" })
keymap.set("n", "<leader>gl", function() Snacks.lazygit.log() end, { desc = "Lazygit Log (cwd)" })

-- Terminal
keymap.set("n", "<c-_/>", function() Snacks.terminal() end, { desc = "Toggle Terminal" }) -- contral + / . It is giving a bit of weird behavior.
keymap.set("n", "<c-_>", function() Snacks.terminal() end, { desc = "which_key_ignore" })

-- Word references
keymap.set({ "n", "t" }, "]]", function() Snacks.words.jump(vim.v.count1) end, { desc = "Next Reference" })
keymap.set({ "n", "t" }, "[[", function() Snacks.words.jump(-vim.v.count1) end, { desc = "Prev Reference" })

keymap.set("n", "<leader>ir", function() Snacks.image.render() end, { desc = "Render Image" })

  -- Neovim News
keymap.set("n", "<leader>N", function() Snacks.win({
  file = vim.api.nvim_get_runtime_file("doc/news.txt", false)[1],
  width = 0.6,
  height = 0.6,
  wo = {
    spell = false,
    wrap = false,
    signcolumn = "yes",
    statuscolumn = " ",
    conceallevel = 3,
  },
}) end, { desc = "Neovim News" })

----------------------------------------------------------------------
-- Toggles (if you also moved them here)
----------------------------------------------------------------------
vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  callback = function()
    local toggles = _G.SnacksToggles
    if not toggles then return end

    keymap.set("n", "<leader>us", function() toggles.spell() end, { desc = "Toggle Spelling" })
    keymap.set("n", "<leader>uw", function() toggles.wrap() end, { desc = "Toggle Wrap" })
    keymap.set("n", "<leader>uL", function() toggles.relativenumber() end, { desc = "Toggle Relative Number" })
    keymap.set("n", "<leader>ud", function() toggles.diagnostics() end, { desc = "Toggle Diagnostics" })
    keymap.set("n", "<leader>ul", function() toggles.line_number() end, { desc = "Toggle Line Number" })
    keymap.set("n", "<leader>uc", function() toggles.conceallevel() end, { desc = "Toggle Conceallevel" })
    keymap.set("n", "<leader>uT", function() toggles.treesitter() end, { desc = "Toggle Treesitter" })
    keymap.set("n", "<leader>ub", function() toggles.background() end, { desc = "Toggle Dark Background" })
    keymap.set("n", "<leader>uh", function() toggles.inlay_hints() end, { desc = "Toggle Inlay Hints" })
    keymap.set("n", "<leader>ug", function() toggles.indent() end, { desc = "Toggle Indent Guides" })
    keymap.set("n", "<leader>uD", function() toggles.dim() end, { desc = "Toggle Dim" })
  end,
})







-- conform.lua:
-- 1) Toggle Conform formatting
keymap.set("n", "<leader>mt", function()
  -- Import your plugin module
  require("idossha.plugins.conform").toggle_formatting()
end, { desc = "Toggle Conform auto-formatting" })

-- 2) Manually format
--    - Works in Normal mode (format buffer)
--    - Works in Visual mode (format selection)
keymap.set({ "n", "v" }, "<leader>mp", function()
  require("conform").format({
    lsp_fallback = true,
    async = false,
    timeout_ms = 3000,
  })
end, { desc = "Format with Conform" })

