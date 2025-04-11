local diagnostic_icons = require('icons').diagnostics
local methods = vim.lsp.protocol.Methods

local M = {}

-- Disable inlay hints initially (and enable if needed with my ToggleInlayHints command).
vim.g.inlay_hints = false

--- Sets up LSP keymaps and autocommands for the given buffer.
---@param client vim.lsp.Client
---@param bufnr integer
local function on_attach(client, bufnr)
    ---@param lhs string
    ---@param rhs string|function
    ---@param desc string
    ---@param mode? string|string[]
    local function keymap(lhs, rhs, desc, mode)
        mode = mode or 'n'
        vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
    end

    require('lightbulb').attach_lightbulb(bufnr, client.id)

    keymap('gra', '<cmd>FzfLua lsp_code_actions<cr>', 'vim.lsp.buf.code_action()', { 'n', 'x' })

    keymap('grr', '<cmd>FzfLua lsp_references<cr>', 'vim.lsp.buf.references()')

    keymap('gy', '<cmd>FzfLua lsp_typedefs<cr>', 'Go to type definition')

    keymap('<leader>fs', '<cmd>FzfLua lsp_document_symbols<cr>', 'Document symbols')
    keymap('<leader>fS', function()
        -- Disable the grep switch header.
        require('fzf-lua').lsp_live_workspace_symbols { no_header_i = true }
    end, 'Workspace symbols')

    keymap('[d', function()
        vim.diagnostic.jump { count = -1 }
    end, 'Previous diagnostic')
    keymap(']d', function()
        vim.diagnostic.jump { count = 1 }
    end, 'Next diagnostic')
    keymap('[e', function()
        vim.diagnostic.jump { count = -1, severity = vim.diagnostic.severity.ERROR }
    end, 'Previous error')
    keymap(']e', function()
        vim.diagnostic.jump { count = 1, severity = vim.diagnostic.severity.ERROR }
    end, 'Next error')

    if client:supports_method(methods.textDocument_definition) then
        keymap('gd', function()
            require('fzf-lua').lsp_definitions { jump1 = true }
        end, 'Go to definition')
        keymap('gD', function()
            require('fzf-lua').lsp_definitions { jump1 = false }
        end, 'Peek definition')
    end

    if client:supports_method(methods.textDocument_signatureHelp) then
        local blink_window = require 'blink.cmp.completion.windows.menu'
        local blink = require 'blink.cmp'

        keymap('<C-k>', function()
            -- Close the completion menu first (if open).
            if blink_window.win:is_open() then
                blink.hide()
            end

            vim.lsp.buf.signature_help()
        end, 'Signature help', 'i')
    end

    if client:supports_method(methods.textDocument_documentHighlight) then
        local under_cursor_highlights_group =
            vim.api.nvim_create_augroup('mariasolos/cursor_highlights', { clear = false })
        vim.api.nvim_create_autocmd({ 'CursorHold', 'InsertLeave' }, {
            group = under_cursor_highlights_group,
            desc = 'Highlight references under the cursor',
            buffer = bufnr,
            callback = vim.lsp.buf.document_highlight,
        })
        vim.api.nvim_create_autocmd({ 'CursorMoved', 'InsertEnter', 'BufLeave' }, {
            group = under_cursor_highlights_group,
            desc = 'Clear highlight references',
            buffer = bufnr,
            callback = vim.lsp.buf.clear_references,
        })
    end

    if client:supports_method(methods.textDocument_inlayHint) and vim.g.inlay_hints then
        local inlay_hints_group = vim.api.nvim_create_augroup('mariasolos/toggle_inlay_hints', { clear = false })

        -- Initial inlay hint display.
        -- Idk why but without the delay inlay hints aren't displayed at the very start.
        vim.defer_fn(function()
            local mode = vim.api.nvim_get_mode().mode
            vim.lsp.inlay_hint.enable(mode == 'n' or mode == 'v', { bufnr = bufnr })
        end, 500)

        vim.api.nvim_create_autocmd('InsertEnter', {
            group = inlay_hints_group,
            desc = 'Enable inlay hints',
            buffer = bufnr,
            callback = function()
                if vim.g.inlay_hints then
                    vim.lsp.inlay_hint.enable(false, { bufnr = bufnr })
                end
            end,
        })

        vim.api.nvim_create_autocmd('InsertLeave', {
            group = inlay_hints_group,
            desc = 'Disable inlay hints',
            buffer = bufnr,
            callback = function()
                if vim.g.inlay_hints then
                    vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
                end
            end,
        })
    end

    -- Add "Fix all" command for ESLint.
    if client.name == 'eslint' then
        vim.keymap.set('n', '<leader>ce', function()
            if not client then
                return
            end

            client:request(vim.lsp.protocol.Methods.workspace_executeCommand, {
                command = 'eslint.applyAllFixes',
                arguments = {
                    {
                        uri = vim.uri_from_bufnr(bufnr),
                        version = vim.lsp.util.buf_versions[bufnr],
                    },
                },
            }, nil, bufnr)
        end, { desc = 'Fix all ESLint errors', buffer = bufnr })
    end
end

-- Define the diagnostic signs.
for severity, icon in pairs(diagnostic_icons) do
    local hl = 'DiagnosticSign' .. severity:sub(1, 1) .. severity:sub(2):lower()
    vim.fn.sign_define(hl, { text = icon, texthl = hl })
end

-- Diagnostic configuration.
vim.diagnostic.config {
    virtual_text = {
        prefix = '',
        spacing = 2,
        format = function(diagnostic)
            -- Use shorter, nicer names for some sources:
            local special_sources = {
                ['Lua Diagnostics.'] = 'lua',
                ['Lua Syntax Check.'] = 'lua',
            }

            local message = diagnostic_icons[vim.diagnostic.severity[diagnostic.severity]]
            if diagnostic.source then
                message = string.format('%s %s', message, special_sources[diagnostic.source] or diagnostic.source)
            end
            if diagnostic.code then
                message = string.format('%s[%s]', message, diagnostic.code)
            end

            return message .. ' '
        end,
    },
    float = {
        source = 'if_many',
        -- Show severity icons as prefixes.
        prefix = function(diag)
            local level = vim.diagnostic.severity[diag.severity]
            local prefix = string.format(' %s ', diagnostic_icons[level])
            return prefix, 'Diagnostic' .. level:gsub('^%l', string.upper)
        end,
    },
    -- Disable signs in the gutter.
    signs = false,
}

-- Override the virtual text diagnostic handler so that the most severe diagnostic is shown first.
local show_handler = vim.diagnostic.handlers.virtual_text.show
assert(show_handler)
local hide_handler = vim.diagnostic.handlers.virtual_text.hide
vim.diagnostic.handlers.virtual_text = {
    show = function(ns, bufnr, diagnostics, opts)
        table.sort(diagnostics, function(diag1, diag2)
            return diag1.severity > diag2.severity
        end)
        return show_handler(ns, bufnr, diagnostics, opts)
    end,
    hide = hide_handler,
}

local hover = vim.lsp.buf.hover
---@diagnostic disable-next-line: duplicate-set-field
vim.lsp.buf.hover = function()
    return hover {
        max_height = math.floor(vim.o.lines * 0.5),
        max_width = math.floor(vim.o.columns * 0.4),
    }
end

local signature_help = vim.lsp.buf.signature_help
---@diagnostic disable-next-line: duplicate-set-field
vim.lsp.buf.signature_help = function()
    return signature_help {
        max_height = math.floor(vim.o.lines * 0.5),
        max_width = math.floor(vim.o.columns * 0.4),
    }
end

-- Update mappings when registering dynamic capabilities.
local register_capability = vim.lsp.handlers[methods.client_registerCapability]
vim.lsp.handlers[methods.client_registerCapability] = function(err, res, ctx)
    local client = vim.lsp.get_client_by_id(ctx.client_id)
    if not client then
        return
    end

    on_attach(client, vim.api.nvim_get_current_buf())

    return register_capability(err, res, ctx)
end

vim.api.nvim_create_autocmd('LspAttach', {
    desc = 'Configure LSP keymaps',
    callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)

        -- I don't think this can happen but it's a wild world out there.
        if not client then
            return
        end

        on_attach(client, args.buf)
    end,
})

-- Set up LSP servers.
vim.api.nvim_create_autocmd({ 'BufReadPre', 'BufNewFile' }, {
    once = true,
    callback = function()
        ---@param name string
        ---@param config vim.lsp.Config
        local function configure_server(name, config)
            vim.lsp.config(name, config)
            vim.lsp.enable(name)
        end

        -- Install with: npm i -g bash-language-server
        -- Also uses shellcheck for diagnostics and shfmt for formatting.
        configure_server('bashls', {
            cmd = { 'bash-language-server', 'start' },
            filetypes = { 'bash', 'sh', 'zsh' },
        })

        -- Install with: npm i -g vscode-langservers-extracted
        configure_server('cssls', {
            cmd = { 'vscode-css-language-server', '--stdio' },
            filetypes = { 'css', 'scss', 'less' },
            settings = {
                css = { validate = true },
                scss = { validate = true },
                less = { validate = true },
            },
        })
        configure_server('eslint', {
            cmd = { 'vscode-eslint-language-server', '--stdio' },
            filetypes = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact', 'graphql' },
            root_markers = { '.eslintrc', '.eslintrc.js', '.eslintrc.json', 'eslint.config.js', 'eslint.config.mjs' },
            -- Using roughly the same defaults as nvim-lspconfig: https://github.com/neovim/nvim-lspconfig/blob/d3ad666b7895f958d088cceb6f6c199672c404fe/lua/lspconfig/configs/eslint.lua#L70
            settings = {
                validate = 'on',
                packageManager = nil,
                useESLintClass = false,
                experimental = { useFlatConfig = false },
                codeActionOnSave = { enable = false, mode = 'all' },
                format = false,
                quiet = false,
                onIgnoredFiles = 'off',
                options = {},
                rulesCustomizations = {},
                run = 'onType',
                problems = { shortenToSingleLine = false },
                nodePath = '',
                workingDirectory = { mode = 'location' },
                codeAction = {
                    disableRuleComment = { enable = true, location = 'separateLine' },
                    showDocumentation = { enable = true },
                },
            },
            before_init = function(params, config)
                -- Set the workspace folder setting for correct search of tsconfig.json files etc.
                config.settings.workspaceFolder = {
                    uri = params.rootPath,
                    name = vim.fn.fnamemodify(params.rootPath, ':t'),
                }
            end,
            ---@type table<string, lsp.Handler>
            handlers = {
                ['eslint/openDoc'] = function(_, params)
                    vim.ui.open(params.url)
                    return {}
                end,
                ['eslint/probeFailed'] = function()
                    vim.notify('LSP[eslint]: Probe failed.', vim.log.levels.WARN)
                    return {}
                end,
                ['eslint/noLibrary'] = function()
                    vim.notify('LSP[eslint]: Unable to load ESLint library.', vim.log.levels.WARN)
                    return {}
                end,
            },
        })
        configure_server('html', {
            cmd = { 'vscode-html-language-server', '--stdio' },
            filetypes = { 'html' },
            embeddedLanguages = { css = true, javascript = true },
        })
        configure_server('jsonls', {
            cmd = { 'vscode-json-language-server', '--stdio' },
            filetypes = { 'json', 'jsonc' },
            settings = {
                json = {
                    validate = { enable = true },
                    schemas = require('schemastore').json.schemas(),
                },
            },
        })

        -- Install with
        -- mac: brew install dprint
        -- Arch: paru -S dprint
        configure_server('dprint', {
            cmd = { 'dprint', 'lsp' },
            filetypes = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact', 'json', 'jsonc', 'graphql' },
        })

        -- Install with
        -- mac: brew install llvm
        -- Arch: pacman -S clang
        configure_server('clangd', {
            cmd = {
                'clangd',
                '--clang-tidy',
                '--header-insertion=iwyu',
                '--completion-style=detailed',
                '--fallback-style=none',
                '--function-arg-placeholders=false',
            },
            filetypes = { 'c', 'cpp' },
            root_markers = { '.clangd' },
        })

        -- Install with
        -- mac: brew install lua-language-server
        -- Arch: pacman -S lua-language-server
        configure_server('lua_ls', {
            cmd = { 'lua-language-server' },
            filetypes = { 'lua' },
            root_markers = { '.luarc.json', '.luarc.jsonc' },
            -- NOTE: These will be merged with the configuration file.
            settings = {
                Lua = {
                    completion = { callSnippet = 'Replace' },
                    -- Using stylua for formatting.
                    format = { enable = false },
                    hint = {
                        enable = true,
                        arrayIndex = 'Disable',
                    },
                    runtime = {
                        version = 'LuaJIT',
                    },
                    workspace = {
                        checkThirdParty = false,
                        library = {
                            vim.env.VIMRUNTIME,
                            '${3rd}/luv/library',
                        },
                    },
                },
            },
        })

        -- Install with: rustup component add rust-analyzer
        configure_server('rust_analyzer', {
            cmd = { 'rust-analyzer' },
            filetypes = { 'rust' },
            root_markers = { 'Cargo.toml', 'rust-project.json' },
            settings = {
                ['rust-analyzer'] = {
                    inlayHints = {
                        -- These are a bit too much.
                        chainingHints = { enable = false },
                    },
                },
            },
        })

        -- Install with: npm i -g stylelint-lsp
        configure_server('stylelint_lsp', {
            cmd = { 'stylelint-lsp', '--stdio' },
            filetypes = { 'css', 'less', 'scss' },
            root_markers = { '.stylelintrc', '.stylelintrc.js', '.stylelintrc.json', 'stylelint.config.js' },
            settings = {
                stylelintplus = {
                    -- Lint on save instead of on type.
                    validateOnSave = true,
                    validateOnType = false,
                },
            },
        })

        -- Install with: cargo install --features lsp --locked taplo-cli
        configure_server('taplo', {
            cmd = { 'taplo', 'lsp', 'stdio' },
            filetypes = { 'toml' },
            settings = {
                -- Use the defaults that the VSCode extension uses: https://github.com/tamasfe/taplo/blob/2e01e8cca235aae3d3f6d4415c06fd52e1523934/editors/vscode/package.json
                taplo = {
                    configFile = { enabled = true },
                    schema = {
                        enabled = true,
                        catalogs = { 'https://www.schemastore.org/api/json/catalog.json' },
                        cache = {
                            memoryExpiration = 60,
                            diskExpiration = 600,
                        },
                    },
                },
            },
        })

        -- Install with: npm i -g add yaml-language-server
        configure_server('yamlls', {
            cmd = { 'yaml-language-server', '--stdio' },
            filetypes = { 'yaml' },
            settings = {
                yaml = {
                    -- Using the schemastore plugin for schemas.
                    schemastore = { enable = false, url = '' },
                    schemas = require('schemastore').yaml.schemas(),
                },
            },
        })

        local jsts_settings = {
            suggest = { completeFunctionCalls = true },
            inlayHints = {
                functionLikeReturnTypes = { enabled = true },
                parameterNames = { enabled = 'literals' },
                variableTypes = { enabled = true },
            },
        }
        -- Install with: @vtsls/language-server
        configure_server('vtsls', {
            cmd = { 'vtsls', '--stdio' },
            filetypes = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' },
            root_markers = { 'tsconfig.json', 'jsonconfig.json' },
            settings = {
                typescript = jsts_settings,
                javascript = jsts_settings,
                vtsls = {
                    -- Automatically use workspace version of TypeScript lib on startup.
                    autoUseWorkspaceTsdk = true,
                    experimental = {
                        -- Inlay hint truncation.
                        maxInlayHintLength = 30,
                        -- For completion performance.
                        completion = {
                            enableServerSideFuzzyMatch = true,
                        },
                    },
                },
            },
        })
    end,
})

return M
