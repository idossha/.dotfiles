return {
  {
    'voldikss/vim-floaterm',
    init = function()
      vim.g.floaterm_keymap_new    = '<F7>'
      vim.g.floaterm_keymap_prev   = '<F8>'
      vim.g.floaterm_keymap_next   = '<F9>'
      vim.g.floaterm_keymap_toggle = '<F12>'
      vim.g.floaterm_keymap_kill   = '<F10>'  -- Add this line to kill/close terminal
    end,
    config = function()
      vim.api.nvim_create_autocmd('FileType', {
        pattern = 'python',
        callback = function()
          vim.api.nvim_set_keymap('n', '<F5>', ':w<CR>:FloatermNew --autoclose=0 python3 %<CR>', { noremap = true, silent = true })
          vim.api.nvim_set_keymap('i', '<F5>', '<ESC>:w<CR>:FloatermNew --autoclose=0 python3 %<CR>', { noremap = true, silent = true })
        end
      })
      
      -- Add these terminal-specific keymaps
      vim.api.nvim_create_autocmd('TermOpen', {
        pattern = '*',
        callback = function()
          -- Set F10 to close the terminal when in terminal mode
          vim.api.nvim_buf_set_keymap(0, 't', '<F10>', '<C-\\><C-n>:FloatermKill<CR>', { noremap = true, silent = true })
          -- Easy escape from terminal mode
          vim.api.nvim_buf_set_keymap(0, 't', '<Esc>', '<C-\\><C-n>', { noremap = true, silent = true })
        end
      })
    end
  },
}
