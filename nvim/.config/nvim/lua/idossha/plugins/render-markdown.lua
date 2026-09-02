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
      pipe_table = {
        -- 'trimmed' caps padding beyond the widest cell so wide tables
        -- stay as narrow as their content allows.
        cell = 'trimmed',
        preset = 'round',
        alignment_indicator = '─',
      },
      latex = {
        enabled = true,
        converter = 'utftex',
        highlight = 'RenderMarkdownMath',
      },
    })
  end,
}

