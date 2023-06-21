local M = {}

---Creates a new autocmd group.
---@param name string
---@return number
M.augroup = function(name)
    return vim.api.nvim_create_augroup(name, { clear = true })
end

return M
