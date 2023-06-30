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
            { '<leader>sr', nil, desc = 'Search recently opened files' },
            { '<leader>sf', nil, desc = 'Search files' },
            { '<leader>sh', nil, desc = 'Search help' },
            { '<leader>sg', nil, desc = 'Search by grep' },
            { '<leader>sb', nil, desc = 'Search fuzzily in buffer' },
        },
        config = function()
            local telescope = require 'telescope'
            local telescope_builtin = require 'telescope.builtin'
            local actions = require 'telescope.actions'
            local nmap = require('helpers.keybindings').nmap

            nmap('<leader>sr', telescope_builtin.oldfiles)
            nmap('<leader>sf', telescope_builtin.find_files)
            nmap('<leader>sh', telescope_builtin.help_tags)
            nmap('<leader>sg', telescope_builtin.live_grep)
            nmap('<leader>sb', function()
                telescope_builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
                    winblend = 10,
                    previewer = false,
                })
            end)

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
