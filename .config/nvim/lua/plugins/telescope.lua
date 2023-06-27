-- Fuzzy finder (files, LSP, etc)
return {
    {
        'nvim-telescope/telescope.nvim',
        dependencies = {
            {
                'nvim-telescope/telescope-fzf-native.nvim',
                build = 'make',
                config = function()
                    require('telescope').load_extension 'fzf'
                end,
            },
            'nvim-lua/plenary.nvim',
        },
        cmd = 'Telescope',
        keys = {
            { '<leader>?', ':Telescope oldfiles<cr>', desc = 'Search recently opened files' },
            { '<leader>sh', ':Telescope help_tags<cr>', desc = 'Search help' },
            {
                '<leader>/',
                function()
                    require('telescope.builtin').current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
                        winblend = 10,
                        previewer = false,
                    })
                end,
                desc = 'Search fuzzily in buffer',
            },
            {
                '<leader>sf',
                function()
                    require('telescope.builtin').find_files()
                end,
                desc = 'Search files',
            },
            {
                '<leader>sg',
                function()
                    require('telescope.builtin').live_grep()
                end,
                desc = 'Search by grep',
            },
        },
        config = function()
            local telescope = require 'telescope'
            local actions = require 'telescope.actions'

            telescope.setup {
                defaults = {
                    mappings = {
                        i = {
                            -- Close with esc, returning to normal mode.
                            ['<esc>'] = function(bufnr)
                                actions.close(bufnr)
                                vim.cmd 'stopinsert'
                            end,
                            -- Clear the search with ctrl-u.
                            ['<C-u>'] = false,
                            -- Use <C-s> to open an horizontal split instead of <C-x>.
                            ['<C-x>'] = false,
                            -- Create splits, returning to normal mode.
                            ['<C-s>'] = function()
                                actions.select_horizontal()
                                vim.cmd 'stopinsert'
                            end,
                            ['<C-v>'] = function()
                                actions.select_vertical()
                                vim.cmd 'stopinsert'
                            end,
                        },
                    },
                    -- Use a vertical layout.
                    layout_config = {
                        vertical = {
                            preview_height = 0.3,
                            preview_cutoff = 0,
                        },
                    },
                    layout_strategy = 'vertical',
                },
            }
        end,
    },
}
