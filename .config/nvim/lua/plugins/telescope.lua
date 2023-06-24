local nmap = require('helpers.keybindings').nmap

-- Fuzzy finder (files, LSP, etc)
return {
    {
        'nvim-telescope/telescope.nvim',
        branch = '0.1.x',
        dependencies = 'nvim-lua/plenary.nvim',
        cmd = 'Telescope',
        init = function()
            local telescope_builtin = require 'telescope.builtin'

            -- Configure bindings for the pickers.
            nmap('<leader>?', telescope_builtin.oldfiles, 'Search recently opened files')
            nmap('<leader>/', function()
                telescope_builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
                    winblend = 10,
                    previewer = false,
                })
            end, 'Search fuzzily in buffer')
            nmap('<leader>sf', telescope_builtin.find_files, 'Search files')
            nmap('<leader>sh', telescope_builtin.help_tags, 'Search help')
            nmap('<leader>sg', telescope_builtin.live_grep, 'Search by grep')
            nmap('<leader>sd', telescope_builtin.diagnostics, 'Search diagnostics')
        end,
        config = function()
            local telescope = require 'telescope'
            local actions = require 'telescope.actions'

            -- Enable telescope fzf native, if installed
            pcall(telescope.load_extension, 'fzf')

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
                                require('telescope.actions').select_horizontal()
                                vim.cmd 'stopinsert'
                            end,
                            ['<C-v>'] = function()
                                require('telescope.actions').select_vertical()
                                vim.cmd 'stopinsert'
                            end,
                            -- Navigate through prompt history.
                            ['<C-j>'] = require('telescope.actions').cycle_history_next,
                            ['<C-k>'] = require('telescope.actions').cycle_history_prev,
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

    -- Fuzzy Finder Algorithm which requires local dependencies to be built.
    {
        'nvim-telescope/telescope-fzf-native.nvim',
        build = 'make',
        cond = function()
            return vim.fn.executable 'make' == 1
        end,
    },
}
