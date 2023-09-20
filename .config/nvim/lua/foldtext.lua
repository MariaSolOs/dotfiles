local M = {}

---Custom function for the text of folded regions.
---@return string
function M.render()
    return string.format('%s   ... %d lines ...', vim.fn.getline(vim.v.foldstart), vim.v.foldend - vim.v.foldstart + 1)
end

vim.wo.foldtext = [[v:lua.require'foldtext'.render()]]

return M
