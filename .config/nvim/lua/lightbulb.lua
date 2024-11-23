--- VSCode-like lightbulb.
--- Implementation inspired from https://github.com/nvimdev/lspsaga.nvim/blob/a751b92b5d765a99fe3a42b9e51c046f81385e15/lua/lspsaga/codeaction/lightbulb.lua

local M = {}

local lb_name = 'mariasolos/lightbulb'
local lb_namespace = vim.api.nvim_create_namespace(lb_name)
local lb_icon = require('icons').diagnostics.HINT
local lb_group = vim.api.nvim_create_augroup(lb_name, {})
local code_action_method = vim.lsp.protocol.Methods.textDocument_codeAction

local timer = vim.uv.new_timer()
assert(timer, 'Timer was not initialized')

local updated_bufnr = nil

--- Updates the current lightbulb.
---@param bufnr number?
---@param line number?
local function update_extmark(bufnr, line)
    if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
        return
    end

    vim.api.nvim_buf_clear_namespace(bufnr, lb_namespace, 0, -1)

    -- Extra check for not being in insert mode here because sometimes the autocommand
    -- fails.
    if not line or vim.startswith(vim.api.nvim_get_mode().mode, 'i') then
        return
    end

    -- Swallow errors.
    pcall(vim.api.nvim_buf_set_extmark, bufnr, lb_namespace, line, -1, {
        virt_text = { { ' ' .. lb_icon, 'DiagnosticSignHint' } },
        hl_mode = 'combine',
    })

    updated_bufnr = bufnr
end

--- Queries the LSP servers for code actions and updates the lightbulb
--- accordingly.
---@param bufnr number
---@param client vim.lsp.Client
local function render(bufnr, client)
    local winnr = vim.api.nvim_get_current_win()
    if vim.api.nvim_win_get_buf(winnr) ~= bufnr then
        return
    end

    local line = vim.api.nvim_win_get_cursor(0)[1] - 1
    local diagnostics = vim.lsp.diagnostic.from(vim.diagnostic.get(bufnr, { lnum = line }))

    ---@type lsp.CodeActionParams
    local params = vim.lsp.util.make_range_params(winnr, client.offset_encoding)
    params.context = {
        diagnostics = diagnostics,
        triggerKind = vim.lsp.protocol.CodeActionTriggerKind.Automatic,
    }

    vim.lsp.buf_request(bufnr, code_action_method, params, function(_, res, _)
        if vim.api.nvim_get_current_buf() ~= bufnr then
            return
        end

        update_extmark(bufnr, (res and #res > 0 and line) or nil)
    end)
end

-- I don't fully understand how this works, kind of just copy-pasted it
-- from lspsaga.
---@param bufnr number
---@param client vim.lsp.Client
local function update(bufnr, client)
    timer:stop()
    update_extmark(updated_bufnr)
    timer:start(100, 0, function()
        timer:stop()
        vim.schedule(function()
            if vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_get_current_buf() == bufnr then
                render(bufnr, client)
            end
        end)
    end)
end

--- Configures autocommands to update the code action lightbulb.
---@param bufnr integer
---@param client_id integer
M.attach_lightbulb = function(bufnr, client_id)
    local client = vim.lsp.get_client_by_id(client_id)

    if not client or not client:supports_method(code_action_method) then
        return
    end

    local buf_group_name = lb_name .. tostring(bufnr)
    if pcall(vim.api.nvim_get_autocmds, { group = buf_group_name, buffer = bufnr }) then
        return
    end

    local lb_buf_group = vim.api.nvim_create_augroup(buf_group_name, { clear = true })
    vim.api.nvim_create_autocmd('CursorMoved', {
        group = lb_buf_group,
        desc = 'Update lightbulb when moving the cursor in normal/visual mode',
        buffer = bufnr,
        callback = function()
            update(bufnr, client)
        end,
    })

    vim.api.nvim_create_autocmd({ 'InsertEnter', 'BufLeave' }, {
        group = lb_buf_group,
        desc = 'Update lightbulb when entering insert mode or leaving the buffer',
        buffer = bufnr,
        callback = function()
            update_extmark(bufnr, nil)
        end,
    })

    vim.api.nvim_create_autocmd('LspDetach', {
        group = lb_group,
        desc = 'Detach code action lightbulb',
        buffer = bufnr,
        callback = function()
            pcall(vim.api.nvim_del_augroup_by_name, lb_name .. tostring(bufnr))
        end,
    })
end

return M
