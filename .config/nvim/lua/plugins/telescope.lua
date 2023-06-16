-- Fuzzy finder (files, LSP, etc)
return {
    {
        'nvim-telescope/telescope.nvim',
        branch = '0.1.x',
        dependencies = { 'nvim-lua/plenary.nvim' },
        cmd = 'Telescope',
        opts = {},
        init = function()
            local telescope_builtin = require 'telescope.builtin'

            -- Configure bindings for the pickers.
            vim.keymap.set('n', '<leader>?', telescope_builtin.oldfiles,
                { desc = '[?] Find recently opened files' })
            vim.keymap.set('n', '<leader>/', function()
                telescope_builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
                    winblend = 10,
                    previewer = false,
                })
            end, { desc = '[/] Fuzzily search in current buffer' })
            vim.keymap.set('n', '<leader>sf', telescope_builtin.find_files, { desc = '[S]earch [F]iles' })
            vim.keymap.set('n', '<leader>sh', telescope_builtin.help_tags, { desc = '[S]earch [H]elp' })
            vim.keymap.set('n', '<leader>sg', telescope_builtin.live_grep, { desc = '[S]earch by [G]rep' })
            vim.keymap.set('n', '<leader>sd', telescope_builtin.diagnostics,
                { desc = '[S]earch [D]iagnostics' })
        end,
        config = function(_, opts)
            local telescope = require 'telescope'

            -- Enable telescope fzf native, if installed
            pcall(telescope.load_extension, 'fzf')

            telescope.setup(opts)
        end
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
