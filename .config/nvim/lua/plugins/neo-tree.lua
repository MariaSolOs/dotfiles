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
            sources = { 'filesystem', 'buffers', 'git_status' },
            popup_border_style = 'rounded',
            event_handlers = {
                -- Auto-close when opening a file.
                {
                    event = 'file_opened',
                    handler = function()
                        require('neo-tree').close_all()
                    end,
                },
            },
            filesystem = {
                follow_current_file = true,
            },
            window = {
                mappings = {
                    ['<space>'] = 'none',
                    ['l'] = 'none',
                    ['w'] = 'none',
                    -- TODO: Find a way to make these mappings show up in the ? menu.
                    -- Go to the first child.
                    ['hh'] = function(state)
                        local node = state.tree:get_node()
                        local parent = state.tree:get_node(node:get_parent_id())
                        if parent:has_children() then
                            local first_sibling = state.tree:get_nodes(parent:get_id())[1]
                            require('neo-tree.ui.renderer').focus_node(state, first_sibling:get_id())
                        end
                    end,
                    -- Go to the last child.
                    ['ll'] = function(state)
                        local node = state.tree:get_node()
                        local parent = state.tree:get_node(node:get_parent_id())
                        if parent:has_children() then
                            local children = state.tree:get_nodes(parent:get_id())
                            require('neo-tree.ui.renderer').focus_node(state, children[#children]:get_id())
                        end
                    end,
                    -- Mappings to toggle the explorer mode.
                    ['e'] = function()
                        require('neo-tree.command').execute { action = 'focus', source = 'filesystem', position = 'left' }
                    end,
                    ['b'] = function()
                        require('neo-tree.command').execute { action = 'focus', source = 'buffers', position = 'left' }
                    end,
                    ['g'] = function()
                        require('neo-tree.command').execute { action = 'focus', source = 'git_status', position = 'left' }
                    end,
                },
            },
            default_component_configs = {
                git_status = {
                    symbols = {
                        deleted = '',
                        renamed = '',
                        untracked = '',
                        ignored = '⊝',
                        unstaged = '',
                        staged = 'ﱣ',
                        conflict = '',
                    },
                },
            },
        },
        keys = {
            {
                '<leader>f',
                function()
                    require('neo-tree.command').execute { toggle = true, dir = vim.loop.cwd() }
                end,
                desc = 'Toggle file explorer',
            },
        },
    },
}
