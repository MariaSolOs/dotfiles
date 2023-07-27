-- Highlight on yank.
vim.api.nvim_create_autocmd('TextYankPost', {
    group = vim.api.nvim_create_augroup('YankHighlight', { clear = true }),
    callback = function()
        vim.highlight.on_yank { higroup = 'Visual' }
    end,
})

-- Resize splits if the window gets resized.
vim.api.nvim_create_autocmd('VimResized', {
    group = vim.api.nvim_create_augroup('ResizeSplits', { clear = true }),
    callback = function()
        vim.cmd 'tabdo wincmd ='
    end,
})

-- Close some filetypes with <q>.
vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('CloseWithQ', { clear = true }),
    pattern = {
        'bookmarks',
        'checkhealth',
        'help',
        'man',
        'qf',
        'spectre_panel',
    },
    callback = function(event)
        vim.bo[event.buf].buflisted = false
        vim.keymap.set('n', 'q', '<cmd>close<cr>', { buffer = event.buf })
    end,
})

-- Check for spelling in text file types.
vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('SpellingCheck', { clear = true }),
    pattern = { 'gitcommit', 'markdown' },
    callback = function()
        vim.opt_local.spell = true
    end,
})

-- Recognize some files known to have JSON with comments.
vim.api.nvim_create_autocmd({ 'BufNewFile', 'BufRead' }, {
    group = vim.api.nvim_create_augroup('RecognizeJsonWithComments', { clear = true }),
    pattern = {
        '.eslintrc.json',
        'tsconfig*.json',
    },
    command = 'setlocal filetype=jsonc',
})
