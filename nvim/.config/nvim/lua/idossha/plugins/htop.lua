return {
  {
    "idossha/htop.nvim",
    config = function()
      vim.keymap.set("n", "<leader>HT", require("htop").open, { desc = "Open floating htop" })
    end,
  },
}

