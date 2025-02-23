local M = {}

---@type LazyFloat?
local terminal = nil

--- Opens an interactive floating terminal.
---@param cmd? string
---@param opts? LazyCmdOptions
function M.float_term(cmd, opts)
    opts = vim.tbl_deep_extend('force', {
        ft = 'lazyterm',
        size = { width = 0.7, height = 0.7 },
        persistent = true,
    }, opts or {})

    if terminal and terminal:buf_valid() and vim.b[terminal.buf].lazyterm_cmd == cmd then
        terminal:toggle()
    else
        terminal = require('lazy.util').float_term(cmd, opts)
        vim.b[terminal.buf].lazyterm_cmd = cmd
    end
end

return M
