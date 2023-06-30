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

            -- Return to normal mode when closing Telescope.
            vim.api.nvim_create_autocmd('User', {
                group = vim.api.nvim_create_augroup('TelescopeEscapeInsert', {}),
                pattern = 'TelescopeResumePost',
                command = 'stopinsert',
            })

            telescope.setup {
                defaults = {
                    mappings = {
                        i = {
                            ['<esc>'] = actions.close,
                            -- Clear the search with ctrl-u.
                            ['<C-u>'] = false,
                            -- Use <C-s> to open an horizontal split instead of <C-x>.
                            ['<C-x>'] = false,
                            ['<C-s>'] = actions.select_horizontal,
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
