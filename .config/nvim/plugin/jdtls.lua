local add_on_file_type = require('vim-pack').add_on_file_type

-- LSP Java extensions.
add_on_file_type('java', {
    {
        src = 'mfussenegger/nvim-jdtls',
        module_name = 'jdtls',
        -- nvim-jdtls has no setup() function, it's invoked per-buffer via start_or_attach.
        setup = false,
        on_setup = function()
            -- I only need this on Mac.
            if vim.uv.os_uname().sysname ~= 'Darwin' then
                return
            end

            local function start_jdtls()
                local cmd = {
                    'java',
                    '-Declipse.application=org.eclipse.jdt.ls.core.id1',
                    '-Dosgi.bundles.defaultStartLevel=4',
                    '-Declipse.product=org.eclipse.jdt.ls.core.product',
                    '-Dlog.protocol=true',
                    '-Dlog.level=ALL',
                    '-Xmx4g',
                    '-XX:+UseG1GC',
                    '-XX:+UseStringDeduplication',
                    '--add-modules=ALL-SYSTEM',
                    '--add-opens',
                    'java.base/java.util=ALL-UNNAMED',
                    '--add-opens',
                    'java.base/java.lang=ALL-UNNAMED',
                    '-jar',
                    vim.fn.glob(
                        vim.env.HOMEBREW_PREFIX .. '/opt/jdtls/libexec/plugins/org.eclipse.equinox.launcher_*.jar'
                    ),
                    '-configuration',
                    vim.env.HOMEBREW_PREFIX .. '/opt/jdtls/libexec/config_mac_arm',
                }

                -- Configure the data directory for the project.
                local root_dir = vim.fs.root(0, { 'settings.gradle', 'build.gradle', 'gradlew', '.git' })
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
                            import = {
                                exclusions = {
                                    '**/build/**',
                                    '**/.gradle/**',
                                    '**/node_modules/**',
                                    '**/.metadata/**',
                                    '**/bin/**',
                                    '**/out/**',
                                },
                            },
                        },
                    },
                }
            end

            vim.api.nvim_create_autocmd('FileType', {
                pattern = 'java',
                callback = start_jdtls,
            })

            -- Attach to the buffer that triggered this load (the FileType autocmd above only
            -- fires for future java buffers).
            if vim.bo.filetype == 'java' then
                start_jdtls()
            end
        end,
    },
})
