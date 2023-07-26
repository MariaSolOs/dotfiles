-- Fuzzy finder (files, LSP, etc)
return {
    {
        'nvim-telescope/telescope.nvim',
        version = false,
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
            {
                '<leader>tr',
                function()
                    require('telescope.builtin').oldfiles()
                end,
                desc = 'Recently opened files',
            },
            {
                '<leader>tf',
                function()
                    require('telescope.builtin').find_files()
                end,
                desc = 'File search',
            },
            {
                '<leader>th',
                function()
                    require('telescope.builtin').help_tags()
                end,
                desc = 'Help',
            },
            {
                '<leader>tg',
                function()
                    require('telescope.builtin').live_grep()
                end,
                desc = 'Grep search',
            },
            {
                '<leader>tb',
                function()
                    require('telescope.builtin').current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
                        winblend = 10,
                        previewer = false,
                    })
                end,
                desc = 'Fuzzy buffer search',
            },
        },
        config = function()
            local telescope = require 'telescope'
            local builtins = require 'telescope.builtin'
            local actions = require 'telescope.actions'

            -- HACK: Set a default fname_width for the LSP pickers.
            local picker_config = {}
            for builtin, _ in pairs(builtins) do
                picker_config[builtin] = { fname_width = 45 }
            end

            telescope.setup {
                defaults = {
                    mappings = {
                        i = {
                            ['<esc>'] = actions.close,
                            ['<C-t>'] = function(...)
                                return require('trouble.providers.telescope').open_with_trouble(...)
                            end,
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
                pickers = picker_config,
            }
        end,
    },
}
