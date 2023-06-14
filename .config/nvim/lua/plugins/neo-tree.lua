-- File tree.
return {
    {
        'nvim-neo-tree/neo-tree.nvim',
        branch = 'v2.x',
        cmd = 'NeoTree',
        dependencies = {
            'nvim-lua/plenary.nvim',
            'nvim-tree/nvim-web-devicons',
            'MunifTanjim/nui.nvim',
        },
        init = function()
            vim.g.neo_tree_remove_legacy_commands = 1
        end,
        opts = {
            event_handlers = {
                -- Auto-close when opening a file.
                {
                    event = 'file_opened',
                    handler = function(_)
                        require('neo-tree').close_all()
                    end
                }
            },
            mappings = {
                -- Make space a noop.
                ['<space>'] = 'none'
            },
            filesystem = {
                follow_current_file = true
            },
            window = {
                mappings = {
                    ['e'] = function()
                        require('neo-tree.command').execute({ action = 'focus', source = 'filesystem', position = 'left' })
                    end,
                    ['b'] = function()
                        require('neo-tree.command').execute({ action = 'focus', source = 'buffers', position = 'left' })
                    end,
                    ['g'] = function()
                        require('neo-tree.command').execute({ action = 'focus', source = 'git_status', position = 'left' })
                    end,
                }
            }
        },
        keys = {
            {
                '<leader>f',
                function()
                    require('neo-tree.command').execute({ toggle = true, dir = vim.loop.cwd() })
                end,
                desc = 'Toggle NeoTree',
            }
        }
    }
}
