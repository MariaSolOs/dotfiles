---VSCode-like lightbulb.
---Implementation inspired from https://github.com/nvimdev/lspsaga.nvim/blob/37cee912e8d1d1d8bd0477e735a82017374061c0/lua/lspsaga/codeaction/lightbulb.lua

local lb_name = 'CodeActionLightbulb'
local lb_namespace = vim.api.nvim_create_namespace(lb_name)
local lb_icon = require('utils.icons').diagnostics.Hint
local lb_group = vim.api.nvim_create_augroup(lb_name, { clear = true })
local code_action_method = vim.lsp.protocol.Methods.textDocument_codeAction
local timer = vim.uv.new_timer()
local updated_bufnr = nil

---@param bufnr number?
---@param row number?
local function update_extmark(bufnr, row)
    if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
        return
    end
    vim.api.nvim_buf_clear_namespace(bufnr, lb_namespace, 0, -1)

    if not row then
        return
    end

    vim.api.nvim_buf_set_extmark(bufnr, lb_namespace, row, -1, {
        virt_text = { { ' ' .. lb_icon, 'DiagnosticSignHint' } },
        hl_mode = 'combine',
    })

    updated_bufnr = bufnr
end

---@param bufnr number
local function render(bufnr)
    local row = vim.api.nvim_win_get_cursor(0)[1] - 1
    local params = vim.lsp.util.make_range_params()
    params.context = {
        diagnostics = vim.lsp.diagnostic.get_line_diagnostics(bufnr),
        triggerKind = vim.lsp.protocol.CodeActionTriggerKind.Automatic,
    }

    vim.lsp.buf_request(bufnr, code_action_method, params, function(_, res, _)
        if vim.api.nvim_get_current_buf() ~= bufnr then
            return
        end

        if res and #res > 0 then
            update_extmark(bufnr, row)
        else
            update_extmark(bufnr, nil)
        end
    end)
end

---@param bufnr number
local function update(bufnr)
    timer:stop()
    update_extmark(updated_bufnr)
    timer:start(100, 0, function()
        timer:stop()
        vim.schedule(function()
            render(bufnr)
        end)
    end)
end

vim.api.nvim_create_autocmd('LspAttach', {
    group = lb_group,
    callback = function(ev)
        local client = vim.lsp.get_client_by_id(ev.data.client_id)

        if not client then
            return
        end
        if not client.supports_method(code_action_method) then
            return
        end

        local buf_group_name = lb_name .. tostring(ev.buf)
        local ok = pcall(vim.api.nvim_get_autocmds, { group = buf_group_name })
        if ok then
            return
        end

        local lb_buf_group = vim.api.nvim_create_augroup(buf_group_name, { clear = true })
        vim.api.nvim_create_autocmd('CursorMoved', {
            group = lb_buf_group,
            buffer = ev.buf,
            callback = function(args)
                update(args.buf)
            end,
        })

        vim.api.nvim_create_autocmd({ 'InsertEnter', 'BufLeave' }, {
            group = lb_buf_group,
            buffer = ev.buf,
            callback = function(args)
                update_extmark(args.buf, nil)
            end,
        })
    end,
})

vim.api.nvim_create_autocmd('LspDetach', {
    group = lb_group,
    callback = function(ev)
        pcall(vim.api.nvim_del_augroup_by_name, lb_name .. tostring(ev.buf))
    end,
})
