local M = {}

---Creates a keybinding in normal mode.
---@param lhs string
---@param rhs string|fun()
---@param opts? string|table
M.nmap = function(lhs, rhs, opts)
    if type(opts) == 'string' then
        opts = { desc = opts }
    else
        opts = opts or {}
    end

    vim.keymap.set('n', lhs, rhs, opts)
end

return M
