-- Highlight, edit, and navigate code.
return {
    {
        'nvim-treesitter/nvim-treesitter',
        dependencies = {
            {
                'nvim-treesitter/nvim-treesitter-context',
                opts = {
                    -- Avoid the sticky context from growing a lot.
                    max_lines = 3,
                    -- Match the context lines to the source code.
                    multiline_threshold = 1,
                    -- Disable it when the window is too small.
                    min_window_height = 20,
                },
                keys = {
                    {
                        '[c',
                        function()
                            -- Jump to previous change when in diffview.
                            if vim.wo.diff then
                                return '[c'
                            else
                                vim.schedule(function()
                                    require('treesitter-context').go_to_context()
                                end)
                                return '<Ignore>'
                            end
                        end,
                        desc = 'Jump to upper context',
                        expr = true,
                    },
                },
            },
        },
        version = false,
        build = ':TSUpdate',
        opts = {
            ensure_installed = {
                'bash',
                'c',
                'cpp',
                'fish',
                'gitcommit',
                'html',
                'javascript',
                'json',
                'json5',
                'jsonc',
                'lua',
                'markdown',
                'markdown_inline',
                'python',
                'query',
                'regex',
                'rust',
                'scss',
                'toml',
                'tsx',
                'typescript',
                'vim',
                'vimdoc',
                'yaml',
            },
            highlight = {
                enable = true,
                disable = function(_, buf)
                    -- Don't disable for read-only buffers.
                    if not vim.bo[buf].modifiable then
                        return false
                    end

                    local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(buf))
                    -- Disable for files larger than 250 KB.
                    return ok and stats and stats.size > (250 * 1024)
                end,
            },
            incremental_selection = {
                enable = true,
                keymaps = {
                    init_selection = '<cr>',
                    node_incremental = '<cr>',
                    scope_incremental = false,
                    node_decremental = '<bs>',
                },
            },
            indent = { enable = true },
        },
        config = function(_, opts)
            local toggle_inc_selection_group =
                vim.api.nvim_create_augroup('mariasolos/toggle_inc_selection', { clear = true })
            vim.api.nvim_create_autocmd('CmdwinEnter', {
                desc = 'Disable incremental selection when entering the cmdline window',
                group = toggle_inc_selection_group,
                command = 'TSBufDisable incremental_selection',
            })
            vim.api.nvim_create_autocmd('CmdwinLeave', {
                desc = 'Enable incremental selection when leaving the cmdline window',
                group = toggle_inc_selection_group,
                command = 'TSBufEnable incremental_selection',
            })

            require('nvim-treesitter.configs').setup(opts)
        end,
    },
}
