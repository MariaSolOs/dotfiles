-- Fuzzy finder (files, LSP, etc).
return {
    {
        'nvim-telescope/telescope.nvim',
        version = false,
        cmd = 'Telescope',
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
        keys = {
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
            { '<leader>tf', '<cmd>Telescope find_files<cr>', desc = 'File search' },
            { '<leader>tg', '<cmd>Telescope live_grep<cr>', desc = 'Grep search' },
            { '<leader>th', '<cmd>Telescope help_tags<cr>', desc = 'Help' },
            { '<leader>tr', '<cmd>Telescope oldfiles<cr>', desc = 'Recently opened files' },
        },
        config = function()
            local telescope = require 'telescope'
            local builtins = require 'telescope.builtin'
            local actions = require 'telescope.actions'
            local action_set = require 'telescope.actions.set'

            local picker_config = {}
            for builtin, _ in pairs(builtins) do
                picker_config[builtin] = {
                    -- Don't show the matched line since it is already in the preview.
                    show_line = false,
                    -- Center and unfold when selecting a result.
                    attach_mappings = function(prompt_bufnr, _)
                        action_set.select:enhance {
                            post = function()
                                vim.cmd ':normal! zv'
                            end,
                        }
                        actions.center(prompt_bufnr)

                        return true
                    end,
                }
            end

            -- Create a named function here instead of an anonymous function in the setup
            -- so that the name appears in Telescope's which-key.
            local open_with_trouble = function(...)
                return require('trouble.providers.telescope').open_with_trouble(...)
            end

            telescope.setup {
                defaults = {
                    mappings = {
                        i = {
                            ['<C-t>'] = open_with_trouble,
                            -- Avoid having to first return to normal mode before closing.
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
                pickers = vim.tbl_deep_extend('force', picker_config, {
                    -- Open Telescope even if there's only one result.
                    lsp_references = { jump_type = 'never' },
                }),
            }
        end,
    },
}
