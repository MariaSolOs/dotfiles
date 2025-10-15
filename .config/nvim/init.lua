-- Global variables.
vim.g.projects_dir = vim.env.HOME .. '/Code'
vim.g.work_projects_dir = '/Volumes/git'

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

-- General setup and goodies (order matters here).
require 'settings'
require 'keymaps'
require 'commands'
require 'autocmds'
require 'statusline'
require 'winbar'
require 'marks'
require 'lsp'

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
    -- None of my plugins use luarocks so disable this.
    rocks = {
        enabled = false,
    },
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

-- Interactive textual undotree:
vim.cmd.packadd 'nvim.undotree'

-- Enable the new experimental command-line features.
require('vim._extui').enable {}
