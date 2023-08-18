local methods = vim.lsp.protocol.Methods

-- Toggle format on save.
local autoformat = true
vim.api.nvim_create_user_command('ToggleAutoFormat', function()
    autoformat = not autoformat
end, {})

---@param bufnr integer
local function format(bufnr)
    if not autoformat then
        return
    end

    local clients = vim.lsp.get_clients {
        bufnr = bufnr,
        method = methods.textDocument_formatting or methods.textDocument_rangeFormatting,
    }

    -- Prioritize formatting with EFM.
    local name = nil
    if vim.tbl_contains(clients, function(client)
            return client.name == 'efm'
        end) then
        name = 'efm'
    end

    if #clients == 0 then
        return
    end

    vim.lsp.buf.format {
        bufnr = bufnr,
        name = name,
        async = #clients == 1,
    }
end

---@param bufnr number
local function setup_inlay_hints(bufnr)
    local inlay_hints_group = vim.api.nvim_create_augroup('ToggleInlayHints', { clear = false })

    -- Initial inlay hint display.
    -- Idk why but without the delay inlay hints aren't displayed at the very start.
    vim.defer_fn(function()
        local mode = vim.api.nvim_get_mode().mode
        vim.lsp.inlay_hint(bufnr, mode == 'n' or mode == 'v')
    end, 500)

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
local function on_attach(buf_client, bufnr)
    local function keymap(lhs, rhs, desc, mode)
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

    -- Set up format on save for some file types and specific projects.
    local local_fmt_command = vim.g.format_command
    if local_fmt_command then
        vim.keymap.set('n', '<leader>cf', function()
            local cursor = vim.api.nvim_win_get_cursor(0)
            vim.cmd(local_fmt_command)
            cursor[1] = math.min(cursor[1], vim.api.nvim_buf_line_count(0))
            vim.api.nvim_win_set_cursor(0, cursor)
        end, { desc = 'Format buffer' })
    end
    if vim.tbl_contains({ 'lua', 'rust' }, vim.bo[bufnr].filetype) then
        vim.api.nvim_create_autocmd('BufWritePre', {
            buffer = bufnr,
            group = vim.api.nvim_create_augroup('FormatOnSave', { clear = false }),
            callback = function()
                format(bufnr)
            end,
        })
    end
end

return on_attach
