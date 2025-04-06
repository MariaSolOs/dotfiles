-- LSP Java extensions.
return {
    {
        'mfussenegger/nvim-jdtls',
        ft = 'java',
        -- I only need this on Mac.
        enabled = function()
            return vim.uv.os_uname().sysname == 'Darwin'
        end,
        config = function()
            vim.api.nvim_create_autocmd('FileType', {
                pattern = 'java',
                callback = function()
                    local cmd = {
                        'java',
                        '-Declipse.application=org.eclipse.jdt.ls.core.id1',
                        '-Dosgi.bundles.defaultStartLevel=4',
                        '-Declipse.product=org.eclipse.jdt.ls.core.product',
                        '-Dlog.protocol=true',
                        '-Dlog.level=ALL',
                        '-Xmx1g',
                        '--add-modules=ALL-SYSTEM',
                        '--add-opens',
                        'java.base/java.util=ALL-UNNAMED',
                        '--add-opens',
                        'java.base/java.lang=ALL-UNNAMED',
                        '-jar',
                        vim.fn.glob(vim.env.HOME .. '/.jdtls/plugins/org.eclipse.equinox.launcher_*.jar'),
                        '-configuration',
                        vim.env.HOME .. '/.jdtls/config_mac_arm',
                    }

                    -- Configure the data directory for the project.
                    local root_dir = vim.fs.root(0, { 'gradlew', '.git' })
                    local project_name = root_dir and vim.fs.basename(root_dir)
                    if project_name then
                        vim.list_extend(cmd, {
                            '-data',
                            vim.fn.stdpath 'cache' .. '/jdtls/' .. project_name .. '/workspace',
                        })
                    end

                    require('jdtls').start_or_attach {
                        cmd = cmd,
                        root_dir = root_dir,
                        settings = {
                            java = {
                                inlayHints = {
                                    parameterNames = { enabled = 'all' },
                                },
                            },
                        },
                    }
                end,
            })
        end,
    },
}
