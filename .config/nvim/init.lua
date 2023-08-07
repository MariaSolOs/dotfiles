-- Setup all my goodies.
require 'settings'
require 'keymaps'
require 'commands'
require 'utils.lightbulb'

-- Install package manager.
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

-- Configure plugins.
require('lazy').setup('plugins', {
    ui = { border = 'rounded' },
    dev = { path = '~/Code' },
})
