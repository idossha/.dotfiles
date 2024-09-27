return {
    'iamcco/markdown-preview.nvim',
    build = 'cd app && npm install',
    ft = { 'markdown' }, -- Load it only for markdown files
    config = function()
        vim.cmd('nnoremap <silent> <F5> :MarkdownPreview<CR>')
        vim.cmd('nnoremap <silent> <F6> :MarkdownPreviewStop<CR>')
    end
}

