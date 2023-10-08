---@diagnostic disable: undefined-global
return {
    s({
        trig = 'td',
        name = 'TODO',
        desc = 'TODO/NOTE/HACK comment',
        show_condition = function()
            local row, col = unpack(vim.api.nvim_win_get_cursor(0))
            local ok, node = pcall(vim.treesitter.get_node, { pos = { row - 1, col - 1 } })

            if not ok or not node then
                return true
            end

            return not vim.iter({ 'string', 'comment' }):any(function(name)
                return node:type():match(name)
            end)
        end,
    }, {
        d(1, function()
            -- Remove leading whitespace from the commentstring.
            local commentstring = vim.bo.commentstring:gsub('%s*%%s', '%%s')
            return sn(nil, {
                c(
                    1,
                    vim.iter.map(function(comment)
                        return t(string.format(commentstring, ' ' .. comment .. ': '))
                    end, { 'TODO', 'NOTE', 'HACK' })
                ),
            })
        end),
    }),
}
