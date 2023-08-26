-- Utility command for clearing macros.
vim.api.nvim_create_user_command('ClearRegisters', function()
    for r in ('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'):gmatch '%a' do
        vim.fn.setreg(r, '')
    end
    vim.cmd 'wshada'
end, { desc = 'Clear registers' })

vim.api.nvim_create_user_command('Todos', function()
    require('fzf-lua').grep { search = [[TODO:|todo!\(.*\)]], no_esc = true }
end, { desc = 'TODOs' })

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
        'checkhealth',
        'help',
        'man',
        'qf',
        'query',
        'spectre_panel',
    },
    callback = function(event)
        vim.keymap.set('n', 'q', '<cmd>close<cr>', { buffer = event.buf })
    end,
})

-- Toggle relative line numbers.
local line_numbers_group = vim.api.nvim_create_augroup('ToggleLineNumbers', {})
vim.api.nvim_create_autocmd({ 'BufEnter', 'FocusGained', 'InsertLeave', 'CmdlineLeave', 'WinEnter' }, {
    group = line_numbers_group,
    callback = function()
        if vim.o.nu and vim.api.nvim_get_mode().mode ~= 'i' then
            vim.opt.relativenumber = true
        end
    end,
})
vim.api.nvim_create_autocmd({ 'BufLeave', 'FocusLost', 'InsertEnter', 'CmdlineEnter', 'WinLeave' }, {
    group = line_numbers_group,
    callback = function()
        if vim.o.nu then
            vim.opt.relativenumber = false
        end
    end,
})
