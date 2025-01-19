return {
  "yetone/avante.nvim",
  event = "VeryLazy",
  lazy = false,
  version = false, -- Set this to "*" to always pull the latest release version, or set it to false to update to the latest code changes.
  opts = {
    provider = "openai", -- Set OpenAI as the default provider
    auto_suggestions_provider = "openai", -- Use OpenAI for auto-suggestions
    openai = {
      model = "gpt-4o-mini",
      temperature = 0.7, -- Adjust temperature if needed
      max_tokens = 4096, -- Set maximum tokens
      api_key = os.getenv("OPENAI_API_KEY"), -- Use environment variable for the API key
    },
    behaviour = {
      auto_suggestions = true, -- Enable auto-suggestions
      auto_set_highlight_group = true,
      auto_set_keymaps = true,
      auto_apply_diff_after_generation = false,
      support_paste_from_clipboard = false,
      minimize_diff = true, -- Remove unchanged lines when applying a code block
    },
    mappings = {
      diff = {
        ours = "co",
        theirs = "ct",
        all_theirs = "ca",
        both = "cb",
        cursor = "cc",
        next = "]x",
        prev = "[x",
      },
      suggestion = {
        accept = "<M-l>",
        next = "<M-]>",
        prev = "<M-[>",
        dismiss = "<C-]>",
      },
      jump = {
        next = "]]",
        prev = "[[",
      },
      submit = {
        normal = "<CR>",
        insert = "<C-s>",
      },
      sidebar = {
        apply_all = "A",
        apply_cursor = "a",
        switch_windows = "<Tab>",
        reverse_switch_windows = "<S-Tab>",
      },
    },
    hints = { enabled = true },
    windows = {
      position = "right", -- The position of the sidebar
      wrap = true, -- Wrap text in the sidebar
      width = 30, -- Sidebar width as a percentage of available width
      sidebar_header = {
        enabled = true, -- Enable the sidebar header
        align = "center", -- Align header text
        rounded = true,
      },
      input = {
        prefix = "> ",
        height = 8, -- Height of the input window in vertical layout
      },
      edit = {
        border = "rounded",
        start_insert = true, -- Start insert mode when opening the edit window
      },
      ask = {
        floating = false, -- Open the 'AvanteAsk' prompt in a floating window
        start_insert = true, -- Start insert mode when opening the ask window
        border = "rounded",
        focus_on_apply = "ours", -- Focus on the applied diff
      },
    },
    highlights = {
      diff = {
        current = "DiffText",
        incoming = "DiffAdd",
      },
    },
    diff = {
      autojump = true,
      list_opener = "copen",
      override_timeoutlen = 500, -- Override timeout for diff mappings
    },
  },
  build = "make", -- Build command for Linux/macOS
  dependencies = {
    "stevearc/dressing.nvim",
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    "hrsh7th/nvim-cmp", -- Autocompletion for Avante commands and mentions
    "nvim-tree/nvim-web-devicons", -- For icons
    "zbirenbaum/copilot.lua", -- For providers='copilot'
    {
      "HakonHarnes/img-clip.nvim",
      event = "VeryLazy",
      opts = {
        providers = "openai",
      },
    },
    {
      'MeanderingProgrammer/render-markdown.nvim',
      opts = {
        file_types = { "markdown", "Avante" },
      },
      ft = { "markdown", "Avante" },
    },
  },
}

