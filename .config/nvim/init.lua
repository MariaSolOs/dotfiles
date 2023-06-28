-- Set <space> as the leader key.
-- Must happen before plugins are required (otherwise the wrong leader will be used).
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- TODO: Add session management.

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

-- Disable this since the mode will be displayed by lualine.
vim.o.showmode = false

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

-- Disable health checks for these providers.
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_node_provider = 0

-- [[ Keymaps ]]
local nmap = require('helpers.keybindings').nmap

-- Make the leader a noop when not followed by something.
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- Remap for dealing with word wrap.
nmap('k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
nmap('j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- Use ';' for opening the command line.
vim.keymap.set({ 'n', 'v' }, ';', ':')

-- Quit Neovim.
nmap('<leader>q', ':qa<cr>', 'Quit Neovim')

-- Command for opening this file and cd-ing into its containing directory.
vim.api.nvim_create_user_command('OpenConfig', ':e $MYVIMRC | :cd %:p:h', {})
nmap('<leader>C', ':OpenConfig<cr>', 'Open Neovim configuration')

-- Adding blank lines in normal mode.
nmap('<S-Enter>', 'o<Esc>', 'Insert a line below')

-- Switch between windows.
nmap('<C-h>', '<C-w>h', 'Move to the left window')
nmap('<C-j>', '<C-w>j', 'Move to the bottom window')
nmap('<C-k>', '<C-w>k', 'Move to the top window')
nmap('<C-l>', '<C-w>l', 'Move to the right window')

-- Exit insert mode.
vim.keymap.set({ 's', 'i', 'n', 'v' }, '<C-s>', '<Esc>:w<cr>', { desc = 'Exit insert mode and save changes.' })

-- Continue insert mode at the end of the line.
vim.keymap.set('i', '<C-a>', '<C-o>$', { silent = true })

-- [[ Auto commands ]]
local augroup = require('helpers.commands').augroup

-- Highlight on yank.
vim.api.nvim_create_autocmd('TextYankPost', {
    group = augroup 'YankHighlight',
    callback = function()
        vim.highlight.on_yank { higroup = 'Search' }
    end,
    pattern = '*',
})

-- Resize splits if the window gets resized.
vim.api.nvim_create_autocmd('VimResized', {
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

-- Recognize some files known to have JSON with comments.
vim.api.nvim_create_autocmd({ 'BufNewFile', 'BufRead' }, {
    group = augroup 'RecognizeJsonWithComments',
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
})
