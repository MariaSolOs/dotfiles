-- Global variables.
vim.g.projects_dir = vim.fn.expand '~/Code'
vim.g.personal_projects_dir = vim.g.projects_dir .. '/Personal'

-- Add binaries installed by mason.nvim to path.
vim.env.PATH = vim.env.PATH .. ':' .. vim.fn.stdpath 'data' .. '/mason/bin'

-- Set my colorscheme.
vim.cmd.colorscheme 'miss-dracula'

-- Install Lazy.
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not vim.uv.fs_stat(lazypath) then
    vim.fn.system {
        'git',
        'clone',
        '--filter=blob:none',
        'https://github.com/folke/lazy.nvim.git',
        '--branch=stable',
        lazypath,
    }
end
vim.opt.rtp = vim.opt.rtp ^ lazypath

---@type LazySpec
local plugins = 'plugins'

-- General setup (order matters here).
require 'settings'
require 'keymaps'
require 'commands'
require 'autocmds'
require 'statusline'

-- Minimal plugins when just displaying the scrollback buffer.
if vim.env.SCROLLBACK_PAGE then
    require 'kitty_scrollback'
    plugins = {
        { 'folke/flash.nvim', import = 'plugins.flash', opts = { prompt = { enabled = false } } },
        { 'itchyny/vim-highlighturl', import = 'plugins.highlighturl' },
        { 'nvim-tree/nvim-web-devicons', import = 'plugins.nvim-web-devicons' },
    }
else
    -- Load my extra goodies otherwise.
    require 'winbar'
    require 'lightbulb'
    require 'marks'
end

-- Configure plugins.
require('lazy').setup(plugins, {
    ui = { border = 'rounded' },
    dev = { path = vim.g.projects_dir },
    install = {
        -- Do not automatically install on startup.
        missing = false,
    },
    -- Don't bother me when tweaking plugins.
    change_detection = { notify = false },
    performance = {
        rtp = {
            -- Stuff I don't use.
            disabled_plugins = {
                'gzip',
                'netrwPlugin',
                'rplugin',
                'tarPlugin',
                'tohtml',
                'tutor',
                'zipPlugin',
            },
        },
    },
})
