return {
  'MeanderingProgrammer/render-markdown.nvim',
  dependencies = {
    'nvim-treesitter/nvim-treesitter',
    'nvim-tree/nvim-web-devicons'
  },
  enabled = true,
  opts = {},
  config = function()
    require('render-markdown').setup({
      heading = {
        width = 'block',
        left_pad = 2,
        right_pad = 4,
      },
    })
  end,
}

