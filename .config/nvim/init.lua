-- Setup all my goodies.
require 'settings'
require 'keymaps'
require 'autocommands'
require 'utils.lightbulb'

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

-- Configure plugins.
require('lazy').setup('plugins', {
    ui = { border = 'rounded' },
    dev = { path = '~/Code' },
})
