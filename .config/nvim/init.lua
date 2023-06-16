-- Set <space> as the leader key.
-- NOTE: Must happen before plugins are required (otherwise the wrong leader will be used).
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

-- [[ Settings ]]
-- Use an indentation of 4 spaces.
vim.o.sw = 4
vim.o.ts = 4
vim.o.et = true

-- Show whitespace.
vim.opt.list = true
vim.opt.listchars = { space = '⋅', trail = '⋅' }

-- Don't show highlights from previous searches.
vim.o.hlsearch = false

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
vim.o.updatetime = 250
vim.o.timeout = true
vim.o.timeoutlen = 300

-- Set completeopt to have a better completion experience.
vim.o.completeopt = 'menuone,noselect'

-- For color themes to look pretty.
vim.o.termguicolors = true

-- Disable some of those annoying hit-enter messages.
vim.opt.shortmess:append 'IWs'

-- nvim-tree needs netrw to be disabled.
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- [[ Keymaps ]]
-- Make the leader a noop when not followed by something.
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- Remap for dealing with word wrap.
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- Use ';' for opening the command line.
vim.keymap.set({ 'n', 'v' }, ';', ':')

-- Quit Neovim.
vim.keymap.set('n', '<leader>q', ':qa<cr>', { desc = 'Quit Neovim' })

-- Adding blank lines in normal mode.
vim.keymap.set('n', '<Enter>', 'o<Esc>', { desc = 'Insert a line below' })
vim.keymap.set('n', '<S-Enter>', 'O<Esc>', { desc = 'Insert a line above' })

-- Switch between windows.
vim.keymap.set('n', '<C-h>', '<C-w>h', { desc = 'Move to the left window' })
vim.keymap.set('n', '<C-j>', '<C-w>j', { desc = 'Move to the bottom window' })
vim.keymap.set('n', '<C-k>', '<C-w>k', { desc = 'Move to the top window' })
vim.keymap.set('n', '<C-l>', '<C-w>l', { desc = 'Move to the right window' })

-- Exit insert mode and save the changes.
vim.keymap.set({ 'i', 'n' }, '<C-s>', '<Esc>:w<cr>', { desc = 'Exit insert mode and save changes.' })

-- [[ Auto commands ]]
local highlight_group = vim.api.nvim_create_augroup('YankHighlight', { clear = true })
vim.api.nvim_create_autocmd('TextYankPost', {
    callback = function()
        vim.highlight.on_yank()
    end,
    group = highlight_group,
    pattern = '*'
})

-- Format on save.
local format_sync_group = vim.api.nvim_create_augroup('Format', { clear = true })
vim.api.nvim_create_autocmd('BufWritePre', {
    pattern = { '*.rs', '*.lua' },
    callback = function()
        vim.lsp.buf.format({ timeout_ms = 200 })
    end,
    group = format_sync_group
})

-- Add rounded borders to hovers.
local open_floating_preview = vim.lsp.util.open_floating_preview
---@diagnostic disable-next-line: duplicate-set-field
function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
    opts.border = 'rounded'
    return open_floating_preview(contents, syntax, opts, ...)
end

-- Configure plugins.
require('lazy').setup('plugins')
