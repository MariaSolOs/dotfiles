local M = {}
local terminals = {}

-- Opens an interactive floating terminal.
function M.float_term(cmd)
    local termkey = vim.inspect { cmd = cmd or 'shell', count = vim.v.count1 }

    if terminals[termkey] and terminals[termkey]:buf_valid() then
        terminals[termkey]:toggle()
    else
        terminals[termkey] = require('lazy.util').float_term(cmd, {
            ft = 'lazyterm',
            size = { width = 0.7, height = 0.7 },
            persistent = true,
        })
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
