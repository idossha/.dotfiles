return {
  'MagicDuck/grug-far.nvim',
  config = function()
    -- optional setup call to override plugin options
    require('grug-far').setup({
      -- options, see Configuration section below
      -- there are no required options atm
      -- engine = 'ripgrep' is default, but 'astgrep' or 'astgrep-rules' can
      -- be specified
    });
    
    -- Basic keybindings for grug-far
    vim.keymap.set('n', '<leader>rr', function() require('grug-far').open() end, 
        { desc = 'Open grug-far find and replace' })
    
    -- For visual mode, pre-fill search with selection
    vim.keymap.set('v', '<leader>rr', function() require('grug-far').with_visual_selection() end,
        { desc = 'Find and replace with visual selection' })
    
    -- For searching within a visual selection range (this is the fixed mapping)
    vim.keymap.set('v', '<leader>rw', function() 
        require('grug-far').open({ visualSelectionUsage = 'operate-within-range' })
    end, { desc = 'Find and replace within selection' })
    
    -- Kill current instance
    vim.keymap.set('n', '<leader>rk', function() require('grug-far').kill_instance(0) end, 
        { desc = 'Kill grug-far instance' })
  end
}
