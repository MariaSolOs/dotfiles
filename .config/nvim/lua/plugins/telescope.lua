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
            { '<leader>?', nil },
            { '<leader>sf', nil },
            { '<leader>sh', nil },
            { '<leader>sg', nil },
            { '<leader>/', nil },
        },
        config = function()
            local telescope = require 'telescope'
            local telescope_builtin = require 'telescope.builtin'
            local actions = require 'telescope.actions'
            local nmap = require('helpers.keybindings').nmap

            nmap('<leader>?', telescope_builtin.oldfiles, 'Search recently opened files')
            nmap('<leader>sf', telescope_builtin.find_files, 'Search files')
            nmap('<leader>sh', telescope_builtin.help_tags, 'Search help')
            nmap('<leader>sg', telescope_builtin.live_grep, 'Search by grep')
            nmap('<leader>/', function()
                telescope_builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
                    winblend = 10,
                    previewer = false,
                })
            end, 'Search fuzzily in buffer')

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
