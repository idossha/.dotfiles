  return {
    'idossha/matlab.nvim',
    ft = 'matlab',
    config = function()
      require('matlab').setup({
        -- Path to MATLAB executable (should be full path)
        executable = '/Applications/MATLAB_R2024a.app/bin/matlab',

        -- UI options
        panel_size = 50,                  -- Size of the tmux pane (in percentage)
        panel_size_type = 'percentage',   -- 'percentage' or 'fixed' (fixed = columns)
        tmux_pane_direction = 'right',    -- Position of the tmux pane ('right', 'below')
        tmux_pane_focus = true,  

        -- Behavior options
        auto_start = true,
        default_mappings = true,
        debug = false,
        minimal_notifications = true,
      })
    end
  }
