local nmap = require('helpers.keybindings').nmap
local augroup = require('helpers.commands').augroup

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
vim.o.completeopt = 'menuone,noselect,noinsert'

-- For color themes to look pretty.
vim.o.termguicolors = true

-- Disable some of those annoying hit-enter messages.
vim.opt.shortmess:append 'IWs'

-- [[ Keymaps ]]
-- Make the leader a noop when not followed by something.
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- Remap for dealing with word wrap.
nmap('k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
nmap('j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- Use ';' for opening the command line.
vim.keymap.set({ 'n', 'v' }, ';', ':')

-- Quit Neovim.
nmap('<leader>q', ':qa<cr>', 'Quit Neovim')

-- Adding blank lines in normal mode.
nmap('<Enter>', 'o<Esc>', 'Insert a line below')
nmap('<S-Enter>', 'O<Esc>', 'Insert a line above')

-- Switch between windows.
nmap('<C-h>', '<C-w>h', 'Move to the left window')
nmap('<C-j>', '<C-w>j', 'Move to the bottom window')
nmap('<C-k>', '<C-w>k', 'Move to the top window')
nmap('<C-l>', '<C-w>l', 'Move to the right window')

-- Exit insert mode and save the changes.
vim.keymap.set({ 'i', 'n' }, '<C-s>', '<Esc>:w<cr>', { desc = 'Exit insert mode and save changes.' })

-- [[ Auto commands ]]
-- Highlight on yank.
vim.api.nvim_create_autocmd('TextYankPost', {
    group = augroup 'YankHighlight',
    callback = function()
        vim.highlight.on_yank { higroup = 'Search' }
    end,
    pattern = '*',
})

-- Resize splits if the window got resized.
vim.api.nvim_create_autocmd({ 'VimResized', 'BufNew' }, {
    group = augroup 'ResizeSplits',
    callback = function()
        vim.cmd 'tabdo wincmd ='
    end,
})

-- Close some filetypes with <q>.
vim.api.nvim_create_autocmd('FileType', {
    group = augroup 'CloseWithQ',
    pattern = {
        'help',
        'man',
        'qf',
        'checkhealth',
    },
    callback = function(event)
        vim.bo[event.buf].buflisted = false
        nmap('q', '<cmd>close<cr>', { buffer = event.buf, silent = true, desc = 'Close the current buffer' })
    end,
})

-- Configure plugins.
require('lazy').setup('plugins', {
    ui = {
        border = 'rounded',
    },
})
