-- Set <space> as the leader key.
-- Must happen before plugins are required (otherwise the wrong leader will be used).
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Install package manager.
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system {
        'git',
        'clone',
        '--filter=blob:none',
        'https://github.com/folke/lazy.nvim.git',
        '--branch=stable',
        lazypath,
    }
end
vim.opt.rtp:prepend(lazypath)

-- Add binaries installed by mason.nvim to path.
vim.env.PATH = vim.env.PATH .. ':' .. vim.fn.stdpath 'data' .. '/mason/bin'

-- [[ Settings ]]
-- Use an indentation of 4 spaces.
vim.o.sw = 4
vim.o.ts = 4
vim.o.et = true

-- Show whitespace.
vim.opt.list = true
vim.opt.listchars = { space = '⋅', trail = '⋅', tab = '  ' }

-- Show line numbers.
vim.wo.number = true

-- Enable mouse mode.
vim.o.mouse = 'a'

-- Sync clipboard between the OS and Neovim.
vim.o.clipboard = 'unnamedplus'

-- Enable break indent.
vim.o.breakindent = true

-- Save undo history.
vim.o.undofile = true

-- Case insensitive searching UNLESS /C or the search has capitals.
vim.o.ignorecase = true
vim.o.smartcase = true

-- Keep signcolumn on by default.
vim.wo.signcolumn = 'yes'

-- Decrease update times and timeouts.
vim.o.updatetime = 200
vim.o.timeout = true
vim.o.timeoutlen = 300

-- Set completeopt to have a better completion experience.
vim.o.completeopt = 'menuone,noselect,noinsert'

-- Disable some of those annoying hit-enter messages.
vim.opt.shortmess:append 'IWs'

-- Use ripgrep for grepping.
vim.o.grepprg = 'rg --vimgrep'
vim.o.grepformat = '%f:%l:%c:%m'

-- Disable health checks for these providers.
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_node_provider = 0

-- [[ Keymaps ]]
-- Make the leader a noop when not followed by something.
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- Remap for dealing with word wrap.
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- Keeping the cursor centered.
vim.keymap.set('n', '<C-d>', '<C-d>zz', { desc = 'Scroll downwards', silent = true })
vim.keymap.set('n', '<C-u>', '<C-u>zz', { desc = 'Scroll upwards', silent = true })
vim.keymap.set('n', 'n', 'nzzzv', { silent = true })
vim.keymap.set('n', 'N', 'Nzzzv', { silent = true })

-- Add undo break-points.
vim.keymap.set('i', ',', ',<c-g>u', { silent = true })
vim.keymap.set('i', '.', '.<c-g>u', { silent = true })
vim.keymap.set('i', ';', ';<c-g>u', { silent = true })

-- Indent while remaining in visual mode.
vim.keymap.set('v', '<', '<gv', { silent = true })
vim.keymap.set('v', '>', '>gv', { silent = true })

-- Command for opening this file.
vim.keymap.set('n', '<leader>C', ':e $MYVIMRC<cr>', { desc = 'Neovim configuration', silent = true })

-- Switch between windows.
vim.keymap.set('n', '<C-h>', '<C-w>h', { desc = 'Move to the left window', silent = true, remap = true })
vim.keymap.set('n', '<C-j>', '<C-w>j', { desc = 'Move to the bottom window', silent = true, remap = true })
vim.keymap.set('n', '<C-k>', '<C-w>k', { desc = 'Move to the top window', silent = true, remap = true })
vim.keymap.set('n', '<C-l>', '<C-w>l', { desc = 'Move to the right window', silent = true, remap = true })

-- Clear search with <esc>
vim.keymap.set('n', '<esc>', ':noh<cr><esc>', { desc = 'Escape and clear hlsearch', silent = true })

-- Exit insert mode and save changes.
vim.keymap.set(
    { 's', 'i', 'n' },
    '<C-s>',
    '<esc>:w<cr>',
    { desc = 'Exit insert mode and save changes.', silent = true }
)

-- HACK: <C-c> doesn't trigger the insert leave event, so remap it to escape so that it does.
vim.keymap.set('i', '<C-c>', '<esc>', { silent = true })

-- Floating terminal.
vim.keymap.set('n', '<M-t>', function()
    require('helpers.float_term').float_term()
end, { desc = 'Open terminal', silent = true })
vim.keymap.set('t', '<M-t>', '<cmd>close<cr>', { desc = 'Close terminal', silent = true })

-- [[ Auto commands ]]
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

-- Go to the last location when opening a buffer.
vim.api.nvim_create_autocmd('BufReadPost', {
    group = vim.api.nvim_create_augroup('GoToLastLocation', { clear = true }),
    callback = function()
        local buf = vim.api.nvim_get_current_buf()
        if vim.tbl_contains({ 'gitcommit' }, vim.bo[buf].filetype) then
            return
        end
        local mark = vim.api.nvim_buf_get_mark(buf, '"')
        local lcount = vim.api.nvim_buf_line_count(buf)
        if mark[1] > 0 and mark[1] <= lcount then
            pcall(vim.api.nvim_win_set_cursor, 0, mark)
        end
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
        'spectre_panel',
    },
    callback = function(event)
        vim.bo[event.buf].buflisted = false
        vim.keymap.set('n', 'q', '<cmd>close<cr>', { buffer = event.buf, silent = true })
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

-- Configure plugins.
require('lazy').setup('plugins', {
    ui = {
        border = 'rounded',
    },
    dev = {
        path = '~/Code',
    },
})
