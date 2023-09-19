local diagnostic_icons = require('icons').diagnostics
local methods = vim.lsp.protocol.Methods

local M = {}

---Returns the editor's capabilities + some overrides.
M.client_capabilities = function()
    return vim.tbl_deep_extend(
        'force',
        vim.lsp.protocol.make_client_capabilities(),
        -- nvim-cmp supports additional completion capabilities, so broadcast that to servers.
        require('cmp_nvim_lsp').default_capabilities(),
        {
            workspace = {
                -- PERF: didChangeWatchedFiles is too slow.
                -- TODO: Remove this when https://github.com/neovim/neovim/issues/23291#issuecomment-1686709265 is fixed.
                didChangeWatchedFiles = { dynamicRegistration = false },
            },
        },
        {
            textDocument = {
                -- Enable folding.
                foldingRange = {
                    dynamicRegistration = false,
                    lineFoldingOnly = true,
                },
            },
        }
    )
end

---Sets up LSP keymaps and autocommands for the given buffer.
---@param client lsp.Client
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

    keymap('gr', '<cmd>FzfLua lsp_references<cr>', 'Go to references')

    keymap('gy', '<cmd>FzfLua lsp_typedefs<cr>', 'Go to type definition')

    keymap('K', vim.lsp.buf.hover, 'Hover')

    keymap('<leader>fs', '<cmd>FzfLua lsp_document_symbols<cr>', 'Document symbols')
    keymap('<leader>fS', function()
        -- Disable the grep switch header.
        require('fzf-lua').lsp_live_workspace_symbols { no_header_i = true }
    end, 'Workspace symbols')

    keymap('<leader>cd', vim.diagnostic.open_float, 'Line diagnostics')
    keymap('[d', vim.diagnostic.goto_prev, 'Previous diagnostic')
    keymap(']d', vim.diagnostic.goto_next, 'Next diagnostic')
    keymap('[e', function()
        vim.diagnostic.goto_prev { severity = vim.diagnostic.severity.ERROR }
    end, 'Previous error')
    keymap(']e', function()
        vim.diagnostic.goto_next { severity = vim.diagnostic.severity.ERROR }
    end, 'Next error')

    if client.supports_method(methods.textDocument_codeAction) then
        keymap('<leader>ca', vim.lsp.buf.code_action, 'Code action', { 'n', 'v' })
    end

    if client.supports_method(methods.textDocument_rename) then
        keymap('<leader>cr', vim.lsp.buf.rename, 'Rename')
    end

    if client.supports_method(methods.textDocument_definition) then
        keymap('gD', '<cmd>FzfLua lsp_definitions<cr>', 'Peek definition')
        keymap('gd', function()
            require('fzf-lua').lsp_definitions { jump_to_single_result = true }
        end, 'Go to definition')
    end

    if client.supports_method(methods.textDocument_signatureHelp) then
        keymap('<C-k>', vim.lsp.buf.signature_help, 'Signature help', 'i')
    end

    if client.supports_method(methods.textDocument_documentHighlight) then
        local under_cursor_highlights_group =
            vim.api.nvim_create_augroup('mariasolos/cursor_highlights', { clear = false })
        vim.api.nvim_create_autocmd({ 'CursorHold', 'InsertLeave', 'BufEnter' }, {
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

    if client.supports_method(methods.textDocument_codeLens) then
        keymap('<leader>cl', vim.lsp.codelens.run, 'Run CodeLens')

        local codelens_group = vim.api.nvim_create_augroup('mariasolos/codelens', { clear = false })
        vim.api.nvim_create_autocmd('InsertEnter', {
            group = codelens_group,
            desc = 'Disable CodeLens in insert mode',
            buffer = bufnr,
            callback = function()
                vim.lsp.codelens.clear(nil, bufnr)
            end,
        })
        vim.api.nvim_create_autocmd({ 'BufEnter', 'CursorHold', 'InsertLeave' }, {
            group = codelens_group,
            desc = 'Refresh CodeLens',
            buffer = bufnr,
            callback = vim.lsp.codelens.refresh,
        })

        -- Initial CodeLens display.
        vim.lsp.codelens.refresh()
    end

    if client.supports_method(methods.textDocument_inlayHint) then
        local inlay_hints_group = vim.api.nvim_create_augroup('mariasolos/toggle_inlay_hints', { clear = false })

        -- Initial inlay hint display.
        -- Idk why but without the delay inlay hints aren't displayed at the very start.
        vim.defer_fn(function()
            local mode = vim.api.nvim_get_mode().mode
            vim.lsp.inlay_hint(bufnr, mode == 'n' or mode == 'v')
        end, 500)

        vim.api.nvim_create_autocmd('InsertEnter', {
            group = inlay_hints_group,
            desc = 'Enable inlay hints',
            buffer = bufnr,
            callback = function()
                vim.lsp.inlay_hint(bufnr, false)
            end,
        })
        vim.api.nvim_create_autocmd('InsertLeave', {
            group = inlay_hints_group,
            desc = 'Disable inlay hints',
            buffer = bufnr,
            callback = function()
                vim.lsp.inlay_hint(bufnr, true)
            end,
        })
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
        -- Show severity icons as prefixes.
        prefix = function(diagnostic)
            return diagnostic_icons[vim.diagnostic.severity[diagnostic.severity]] .. ' '
        end,
        -- Show only the first line of each diagnostic.
        format = function(diagnostic)
            return vim.split(diagnostic.message, '\n')[1]
        end,
    },
    float = {
        border = 'rounded',
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

local md_namespace = vim.api.nvim_create_namespace 'mariasolos/lsp_float'

---LSP handler that adds extra inline highlights, keymaps, and window options.
---Code inspired from `noice`.
---@param handler fun(err: any, result: any, ctx: any, config: any): integer, integer
---@return function
local function enhanced_float_handler(handler)
    return function(err, result, ctx, config)
        local buf, win = handler(
            err,
            result,
            ctx,
            vim.tbl_deep_extend('force', config or {}, {
                border = 'rounded',
                max_height = math.floor(vim.o.lines * 0.5),
                max_width = math.floor(vim.o.columns * 0.4),
            })
        )

        if not buf or not win then
            return
        end

        -- Conceal everything.
        vim.wo[win].concealcursor = 'n'

        -- Extra highlights.
        for l, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
            for pattern, hl_group in pairs {
                ['|%S-|'] = '@text.reference',
                ['@%S+'] = '@parameter',
                ['^%s*(Parameters:)'] = '@text.title',
                ['^%s*(Return:)'] = '@text.title',
                ['^%s*(See also:)'] = '@text.title',
                ['{%S-}'] = '@parameter',
            } do
                local from = 1 ---@type integer?
                while from do
                    local to
                    from, to = line:find(pattern, from)
                    if from then
                        vim.api.nvim_buf_set_extmark(buf, md_namespace, l - 1, from - 1, {
                            end_col = to,
                            hl_group = hl_group,
                        })
                    end
                    from = to and to + 1 or nil
                end
            end
        end

        -- Add keymaps for opening links.
        if not vim.b[buf].markdown_keys then
            vim.keymap.set('n', 'K', function()
                -- Vim help links.
                local url = (vim.fn.expand '<cWORD>' --[[@as string]]):match '|(%S-)|'
                if url then
                    return vim.cmd.help(url)
                end

                -- Markdown links.
                local col = vim.api.nvim_win_get_cursor(0)[2] + 1
                local from, to
                from, to, url = vim.api.nvim_get_current_line():find '%[.-%]%((%S-)%)'
                if from and col >= from and col <= to then
                    vim.system({ 'open', url }, nil, function(res)
                        if res.code ~= 0 then
                            vim.notify('Failed to open URL' .. url, vim.log.levels.ERROR)
                        end
                    end)
                end
            end, { buffer = buf, silent = true })
            vim.b[buf].markdown_keys = true
        end
    end
end

vim.lsp.handlers[methods.textDocument_hover] = enhanced_float_handler(vim.lsp.handlers.hover)
vim.lsp.handlers[methods.textDocument_signatureHelp] = enhanced_float_handler(vim.lsp.handlers.signature_help)

-- Update mappings when registering dynamic capabilities.
local register_method = vim.lsp.protocol.Methods.client_registerCapability
local register_capability = vim.lsp.handlers[register_method]
vim.lsp.handlers[register_method] = function(err, res, ctx)
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

return M
