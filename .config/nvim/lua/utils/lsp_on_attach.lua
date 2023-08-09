local methods = vim.lsp.protocol.Methods

-- Toggle format on save.
local autoformat = true
vim.api.nvim_create_user_command('ToggleAutoFormat', function()
    autoformat = not autoformat
end, {})

---Formats the current buffer using the assigned formatter.
---@param explicit boolean?
local format = function(explicit)
    if not autoformat and not explicit then
        return
    end

    local buf = vim.api.nvim_get_current_buf()
    local ft = vim.bo[buf].filetype

    -- When a null-ls formatter is available for the current filetype, only null-ls formatters are returned.
    local null_ls = package.loaded['null-ls'] and require('null-ls.sources').get_available(ft, 'NULL_LS_FORMATTING')
        or {}
    local clients = vim.lsp.get_clients { bufnr = buf }
    local available = {}
    for _, client in ipairs(clients) do
        if
            client.supports_method(methods.textDocument_formatting)
            or client.supports_method(methods.textDocument_rangeFormatting)
        then
            if (#null_ls > 0 and client.name == 'null-ls') or #null_ls == 0 then
                table.insert(available, client.id)
            end
        end
    end

    if #available == 0 then
        return
    end

    vim.lsp.buf.format {
        bufnr = buf,
        filter = function(client)
            return vim.tbl_contains(available, client.id)
        end,
    }
end

---@param bufnr number
local setup_inlay_hints = function(bufnr)
    local inlay_hints_group = vim.api.nvim_create_augroup('ToggleInlayHints', { clear = false })

    -- Initial inlay hint display.
    local mode = vim.api.nvim_get_mode().mode
    vim.lsp.inlay_hint(bufnr, mode == 'n' or mode == 'v')

    vim.api.nvim_create_autocmd('InsertEnter', {
        group = inlay_hints_group,
        buffer = bufnr,
        callback = function()
            vim.lsp.inlay_hint(bufnr, false)
        end,
    })
    vim.api.nvim_create_autocmd('InsertLeave', {
        group = inlay_hints_group,
        buffer = bufnr,
        callback = function()
            vim.lsp.inlay_hint(bufnr, true)
        end,
    })
end

---Sets up LSP keymaps and autocommands for the given buffer.
local on_attach = function(buf_client, bufnr)
    local keymap = function(lhs, rhs, desc, mode)
        mode = mode or 'n'
        vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
    end

    if buf_client.supports_method(methods.textDocument_codeAction) then
        keymap('<leader>ca', vim.lsp.buf.code_action, 'Code action', { 'n', 'v' })
    end

    if buf_client.supports_method(methods.textDocument_rename) then
        vim.keymap.set('n', '<leader>cr', vim.lsp.buf.rename, { desc = 'Rename' })
    end

    if buf_client.supports_method(methods.textDocument_definition) then
        keymap('gd', function()
            require('telescope.builtin').lsp_definitions { reuse_win = true }
        end, 'Go to definition')
    end

    if buf_client.supports_method(methods.textDocument_signatureHelp) then
        keymap('<C-k>', vim.lsp.buf.signature_help, 'Signature help', 'i')
    end

    keymap('gr', '<cmd>Telescope lsp_references<cr>', 'Go to references')
    keymap('gI', function()
        require('telescope.builtin').lsp_implementations { reuse_win = true }
    end, 'Go to implementation')
    keymap('gD', function()
        require('telescope.builtin').lsp_type_definitions { reuse_win = true }
    end, 'Go to type definition')

    keymap('<leader>td', function()
        require('telescope.builtin').lsp_document_symbols()
    end, 'Document symbols')
    keymap('<leader>tw', function()
        require('telescope.builtin').lsp_dynamic_workspace_symbols()
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

    -- noice deals with the UI.
    keymap('K', vim.lsp.buf.hover, 'Hover')

    -- Enable inlay hints if the client supports it.
    if buf_client.supports_method(methods.textDocument_inlayHint) then
        setup_inlay_hints(bufnr)
    end

    -- Formatting setup.
    if buf_client.supports_method(methods.textDocument_formatting) then
        keymap('<leader>cf', function()
            format(true)
        end, 'Format buffer')
    end
    if buf_client.supports_method(methods.textDocument_rangeFormatting) then
        keymap('<leader>cf', function()
            format(true)
        end, 'Format selection', 'v')
    end
    vim.api.nvim_create_autocmd('BufWritePre', {
        group = vim.api.nvim_create_augroup('FormatOnSave', { clear = true }),
        callback = function()
            format(false)
        end,
    })
end

return on_attach
