-- Fuzzy finder (files, LSP, etc)
return {
    {
        'nvim-telescope/telescope.nvim',
        branch = '0.1.x',
        dependencies = { 'nvim-lua/plenary.nvim' },
        cmd = 'Telescope',
        opts = {
            defaults = {
                layout_strategy = 'vertical',
            },
        },
        init = function()
            local telescope_builtin = require 'telescope.builtin'

            -- Configure bindings for the pickers.
            vim.keymap.set('n', '<leader>?', telescope_builtin.oldfiles, { desc = 'Search recently opened files' })
            vim.keymap.set('n', '<leader>/', function()
                telescope_builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
                    winblend = 10,
                    previewer = false,
                })
            end, { desc = 'Search fuzzily in buffer' })
            vim.keymap.set('n', '<leader>sf', telescope_builtin.find_files, { desc = 'Search files' })
            vim.keymap.set('n', '<leader>sh', telescope_builtin.help_tags, { desc = 'Search help' })
            vim.keymap.set('n', '<leader>sg', telescope_builtin.live_grep, { desc = 'Search by grep' })
            vim.keymap.set('n', '<leader>sd', telescope_builtin.diagnostics, { desc = 'Search diagnostics' })
        end,
        config = function(_, opts)
            local telescope = require 'telescope'

            -- Enable telescope fzf native, if installed
            pcall(telescope.load_extension, 'fzf')

            telescope.setup(opts)
        end,
    },

    -- Fuzzy Finder Algorithm which requires local dependencies to be built.
    {
        'nvim-telescope/telescope-fzf-native.nvim',
        build = 'make',
        cond = function()
            return vim.fn.executable 'make' == 1
        end,
    },
}
