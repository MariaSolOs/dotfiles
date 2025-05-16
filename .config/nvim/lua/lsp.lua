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

    keymap('gra', function()
        -- Use "silent" to avoid the warning about `vim.ui.select` not being registered with fzf-lua.
        -- I do this dynamically when first calling `vim.ui.select`.
        require('fzf-lua').lsp_code_actions { silent = true }
    end, 'vim.lsp.buf.code_action()', { 'n', 'x' })

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

    vim.lsp.document_color.enable(true, bufnr)

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

    if client:supports_method(methods.textDocument_inlayHint) then
        local inlay_hints_group = vim.api.nvim_create_augroup('mariasolos/toggle_inlay_hints', { clear = false })

        if vim.g.inlay_hints then
            -- Initial inlay hint display.
            -- Idk why but without the delay inlay hints aren't displayed at the very start.
            vim.defer_fn(function()
                local mode = vim.api.nvim_get_mode().mode
                vim.lsp.inlay_hint.enable(mode == 'n' or mode == 'v', { bufnr = bufnr })
            end, 500)
        end

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
        local server_configs = vim.iter(vim.api.nvim_get_runtime_file('lsp/*.lua', true))
            :map(function(file)
                return vim.fn.fnamemodify(file, ':t:r')
            end)
            :totable()
        vim.lsp.enable(server_configs)
    end,
})

return M
