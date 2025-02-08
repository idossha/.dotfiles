-- make sure yark is installed
-- `npm install --global yarn`
-- 'yarn --version'
-- exit nvim
-- call lazy

return {
  "iamcco/markdown-preview.nvim",
  ft = { "markdown" }, -- Load only for Markdown files
  cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
  build = "cd app && yarn install", -- Use shell command for build
}
