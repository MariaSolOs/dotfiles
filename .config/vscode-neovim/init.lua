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

-- [[ Keymaps ]]
-- Make the leader a noop when not followed by something.
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- Window navigation.
vim.keymap.set('n', '<C-h>', ":call VSCodeNotify('workbench.action.focusLeftGroup')<cr>")
vim.keymap.set('n', '<C-j>', ":call VSCodeNotify('workbench.action.focusBelowGroup')<cr>")
vim.keymap.set('n', '<C-k>', ":call VSCodeNotify('workbench.action.focusAboveGroup')<cr>")
vim.keymap.set('n', '<C-l>', ":call VSCodeNotify('workbench.action.focusRightGroup')<cr>")

-- Sync clipboard between the OS and Neovim.
vim.o.clipboard = 'unnamedplus

-- Highlight on yank.
vim.api.nvim_create_autocmd('TextYankPost', {
    group = vim.api.nvim_create_augroup('YankHighlight', {}),
    callback = function()
        vim.highlight.on_yank { higroup = 'Search' }
    end,
    pattern = '*',
})

-- Configure plugins.
require('lazy').setup({
    {
        'nvim-treesitter/nvim-treesitter',
        event = { 'BufReadPost', 'BufNewFile' },
        opts = {
            incremental_selection = {
                enable = true,
                keymaps = {
                    init_selection = '<cr>',
                    node_incremental = '<cr>',
                    scope_incremental = false,
                    node_decremental = '<bs>',
                },
            },
        },
        config = function(_, opts)
            require('nvim-treesitter.configs').setup(opts)
        end,
    },

    {
        'folke/flash.nvim',
        event = 'VeryLazy',
        keys = {
            {
                's',
                mode = { 'n', 'x', 'o' },
                function()
                    require('flash').jump()
                end,
            },
        },
        config = true
    },
})