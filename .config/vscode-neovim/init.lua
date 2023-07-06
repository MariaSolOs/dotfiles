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
-- Sync clipboard between the OS and Neovim.
vim.o.clipboard = 'unnamedplus'

-- Case insensitive searching UNLESS /C or the search has capitals.
vim.o.ignorecase = true
vim.o.smartcase = true

-- Disable some of those annoying hit-enter messages.
vim.opt.shortmess:append 'IWs'

-- [[ Keymaps ]]
-- Window/tab navigation.
vim.keymap.set('n', '<C-h>', ":call VSCodeNotify('workbench.action.focusLeftGroup')<cr>")
vim.keymap.set('n', '<C-j>', ":call VSCodeNotify('workbench.action.focusBelowGroup')<cr>")
vim.keymap.set('n', '<C-k>', ":call VSCodeNotify('workbench.action.focusAboveGroup')<cr>")
vim.keymap.set('n', '<C-l>', ":call VSCodeNotify('workbench.action.focusRightGroup')<cr>")
vim.keymap.set('n', '[t', ":call VSCodeNotify('workbench.action.previousEditorInGroup')<cr>")
vim.keymap.set('n', ']t', ":call VSCodeNotify('workbench.action.nextEditorInGroup')<cr>")

-- Extra language service mappings.
vim.keymap.set('n', 'gt', ":call VSCodeNotify('editor.action.goToTypeDefinition')<cr>")
vim.keymap.set('n', 'gr', ":call VSCodeNotify('references-view.findReferences')<cr>")

-- [[ Autocommands ]]
-- Highlight on yank.
vim.api.nvim_create_autocmd('TextYankPost', {
    group = vim.api.nvim_create_augroup('YankHighlight', {}),
    callback = function()
        vim.highlight.on_yank { higroup = 'Search' }
    end,
    pattern = '*',
})

-- Configure plugins.
require('lazy').setup (
    {
        {
            'folke/flash.nvim',
            event = 'VeryLazy',
            config = true,
            keys = {
                {
                    's',
                    mode = { 'n', 'x', 'o' },
                    function()
                        require('flash').jump()
                    end,
                },
            },
        },
        {
            'nvim-treesitter/nvim-treesitter',
            dependencies = 'nvim-treesitter/nvim-treesitter-textobjects',
            event = { 'BufReadPost', 'BufNewFile' },
            opts = {
                highlight = {
                    enable = false
                },
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
            end
        },
    }, 
    {
        checker = {
            enabled = false
        },
        change_detection = {
            enabled = false
        }
    }
)