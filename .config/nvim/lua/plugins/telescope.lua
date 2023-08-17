-- Fuzzy finder (files, LSP, etc).
return {
    { 'nvim-telescope/telescope-symbols.nvim', lazy = true },
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
                '<leader>tF',
                '<cmd>Telescope find_files no_ignore=true hidden=true<cr>',
                desc = 'File search (with hidden and .gitignored)',
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
            { '<leader>tf', '<cmd>Telescope find_files<cr>', desc = 'File search' },
            { '<leader>tg', '<cmd>Telescope live_grep<cr>', desc = 'Grep search' },
            { '<leader>th', '<cmd>Telescope help_tags<cr>', desc = 'Help' },
            {
                '<leader>ti',
                function()
                    require('lazy').load { plugins = { 'telescope-symbols.nvim' } }
                    require('telescope.builtin').symbols()
                end,
                desc = 'Icon picker',
            },
            { '<leader>tr', '<cmd>Telescope oldfiles<cr>', desc = 'Recently opened files' },
        },
        config = function()
            local telescope = require 'telescope'
            local builtins = require 'telescope.builtin'
            local actions = require 'telescope.actions'
            local action_set = require 'telescope.actions.set'
            local transform_mod = require('telescope.actions.mt').transform_mod

            local picker_config = {}
            for builtin, _ in pairs(builtins) do
                picker_config[builtin] = {
                    -- Don't show the matched line since it is already in the preview.
                    show_line = false,
                    -- Give more space to show the filename.
                    fname_width = 50,
                    -- Center and unfold when selecting a result.
                    attach_mappings = function(prompt_bufnr, _)
                        action_set.select:enhance {
                            post = function()
                                vim.cmd ':normal! zv'
                                actions.center(prompt_bufnr)
                            end,
                        }

                        return true
                    end,
                }
            end

            -- Extra actions for Trouble interop.
            local extras = {}
            extras.open_with_trouble = function(...)
                return require('trouble.providers.telescope').open_with_trouble(...)
            end
            extras.open_qflist = function()
                require('trouble').open 'quickfix'
            end
            extras = transform_mod(extras)

            telescope.setup {
                defaults = {
                    mappings = {
                        i = {
                            -- Trouble mappings.
                            ['<C-t>'] = extras.open_with_trouble,
                            ['<C-q>'] = actions.smart_send_to_qflist + extras.open_qflist,
                            -- Avoid having to first return to normal mode before closing.
                            ['<esc>'] = actions.close,
                            -- Clear the search with ctrl-u.
                            ['<C-u>'] = false,
                            -- Use <C-s> to open an horizontal split instead of <C-x>.
                            ['<C-x>'] = false,
                            ['<C-s>'] = actions.select_horizontal,
                            -- Scroll the preview window.
                            ['<C-f>'] = actions.preview_scrolling_down,
                            ['<C-b>'] = actions.preview_scrolling_up,
                            -- Disable stuff I don't use.
                            ['<C-c>'] = false,
                            ['<M-f>'] = false,
                            ['<M-k>'] = false,
                            ['<M-q>'] = false,
                            ['<PageUp>'] = false,
                            ['<PageDown>'] = false,
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
