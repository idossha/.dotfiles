return {
  "idossha/lazyclaude.nvim",
  keys = {
    { "<leader>lc", "<cmd>LazyClaude<cr>", desc = "LazyClaude" },
  },
  config = function()
    require("lazyclaude").setup()
  end,
}
