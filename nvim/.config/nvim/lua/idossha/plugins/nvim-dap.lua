return {
  "mfussenegger/nvim-dap",
  dependencies = {
    "rcarriga/nvim-dap-ui",
    "nvim-neotest/nvim-nio",
    "mfussenegger/nvim-dap-python",
    "theHamsta/nvim-dap-virtual-text",
  },
  config = function()
    local dap = require("dap")
    local dapui = require("dapui")
    local dap_python = require("dap-python")

    -- Python DAP setup
    dap_python.setup("~/.virtualenvs/debugpy/bin/python")
    dap_python.test_runner = "pytest"

    -- DAP UI setup
    dapui.setup()

    -- Virtual text setup - ensure it's loaded after DAP is initialized
    local virtual_text = require("nvim-dap-virtual-text")
    virtual_text.setup({
      commented = true,  -- Show virtual text as comments
      only_first_definition = false,  -- Show on all variable occurrences, not just first definition
    })

    -- Ensure virtual text highlight groups are visible
    vim.api.nvim_set_hl(0, 'NvimDapVirtualText', { fg = '#ff6b6b', italic = true })
    vim.api.nvim_set_hl(0, 'NvimDapVirtualTextChanged', { fg = '#4ecdc4', italic = true })
    vim.api.nvim_set_hl(0, 'NvimDapVirtualTextError', { fg = '#ff4757', bold = true })
    vim.api.nvim_set_hl(0, 'NvimDapVirtualTextInfo', { fg = '#3742fa', italic = true })

    -- Debug: print when virtual text is enabled
    vim.notify("DAP Virtual Text enabled", vim.log.levels.INFO)

    -- Automatically open/close DAP UI
    dap.listeners.after.event_initialized["dapui_config"] = function() dapui.open() end
    dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
    dap.listeners.before.event_exited["dapui_config"] = function() dapui.close() end
  end,
  keys = {
    -- Continue / step
    { "<leader>dc", function() require("dap").continue() end, desc = "Debug: Continue" },
    { "<leader>dn", function() require("dap").step_over() end, desc = "Debug: Step Over" },
    { "<leader>di", function() require("dap").step_into() end, desc = "Debug: Step Into" },
    { "<leader>do", function() require("dap").step_out() end, desc = "Debug: Step Out" },

    -- Breakpoints
    { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Debug: Toggle Breakpoint" },
    { "<leader>dB", function() require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: ")) end, desc = "Debug: Conditional Breakpoint"},
    { "<leader>dl", function() require("dap").set_breakpoint(nil, nil, vim.fn.input("Log point message: ")) end, desc = "Debug: Log Point"},

    -- UI / REPL
    { "<leader>dr", function() require("dap").repl.open() end, desc = "Debug: Open REPL" },
    { "<leader>du", function() require("dapui").toggle() end, desc = "Debug: Toggle UI" },
    { "<leader>dq", function() require("dap").terminate() end, desc = "Debug: Stop/Quit Session" },

    -- Virtual Text Testing
    { "<leader>dt", function()
      local virtual_text = require("nvim-dap-virtual-text")
      virtual_text.toggle()
      vim.notify("Virtual Text toggled", vim.log.levels.INFO)
    end, desc = "Debug: Toggle Virtual Text" },
  },
}

