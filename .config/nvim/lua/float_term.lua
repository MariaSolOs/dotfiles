local M = {}

---@type table<string, LazyFloat>
local terminals = {}

--- Opens an interactive floating terminal.
---@param cmd? string
---@param opts table
---@return LazyFloat
function M.float_term(cmd, opts)
    opts = vim.tbl_deep_extend('force', {
        ft = 'lazyterm',
        size = { width = 0.7, height = 0.7 },
        persistent = true,
    }, opts)

    local termkey = vim.inspect { cmd = cmd or 'shell', cwd = opts.cwd, count = vim.v.count1 }

    if terminals[termkey] and terminals[termkey]:buf_valid() then
        terminals[termkey]:toggle()
    else
        terminals[termkey] = require('lazy.util').float_term(cmd, opts)
        local buf = terminals[termkey].buf
        vim.b[buf].lazyterm_cmd = cmd

        vim.api.nvim_create_autocmd('BufEnter', {
            buffer = buf,
            callback = function()
                vim.cmd.startinsert()
            end,
        })
    end

    return terminals[termkey]
end

return M
