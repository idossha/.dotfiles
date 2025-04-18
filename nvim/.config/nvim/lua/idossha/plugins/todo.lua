return {
  'idossha/todo.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
  },
  config = function()
    require('todo').setup({
      storage = {
        path = vim.fn.stdpath("data") .. "/todo.json",
      },
    })
  end
}
