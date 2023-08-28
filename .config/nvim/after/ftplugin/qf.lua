-- Some settings.
vim.wo.nu = true
vim.o.buflisted = false

-- Add the cfilter plugin.
vim.cmd.packadd 'cfilter'

-- Deleting entries.
local function list_delete()
    -- Figure out if we're in the quickfix list or the location list.
    local is_qf = vim.fn.getqflist({ winid = 0 }).winid ~= 0
    local list = is_qf and vim.fn.getqflist() or vim.fn.getloclist(0)

    local buf = vim.api.nvim_get_current_buf()
    local line = vim.api.nvim_win_get_cursor(0)[1]

    -- Filter out the current entry or selection.
    if vim.api.nvim_get_mode().mode:match '[vV]' then
        local first_line = vim.fn.getpos("'<")[2]
        local last_line = vim.fn.getpos("'>")[2]
        list = vim.iter(ipairs(list)):filter(function(i)
            return i < first_line or i > last_line
        end)
    else
        table.remove(list, line)
    end

    -- Replace items in the current list.
    if is_qf then
        vim.fn.setqflist({}, 'r', { items = list })
    else
        vim.fn.setloclist(0, {}, 'r', { items = list })
    end

    -- Restore cursor position.
    vim.fn.setpos('.', { buf, line, 1, 0 })
end
vim.keymap.set('n', 'dd', list_delete, { desc = 'Delete current quickfix entry', buffer = 0 })
vim.keymap.set('v', 'd', list_delete, { desc = 'Delete selected quickfix entry', buffer = 0 })
