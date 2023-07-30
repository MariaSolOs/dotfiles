-- Fuzzy finder (files, LSP, etc)
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
            { '<leader>tr', '<cmd>Telescope oldfiles<cr>', desc = 'Recently opened files' },
            { '<leader>tf', '<cmd>Telescope find_files<cr>', desc = 'File search' },
            { '<leader>th', '<cmd>Telescope help_tags<cr>', desc = 'Help' },
            { '<leader>tg', '<cmd>Telescope live_grep<cr>', desc = 'Grep search' },
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
            local action_set = require 'telescope.actions.set'

            -- HACK: Set defaults for all pickers.
            local picker_config = {}
            for builtin, _ in pairs(builtins) do
                picker_config[builtin] = {
                    fname_width = 45,
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
                pickers = vim.tbl_extend('force', picker_config, {
                    -- Open Telescope even if there's only one result.
                    lsp_references = { jump_type = 'never' },
                }),
            }
        end,
    },
}
