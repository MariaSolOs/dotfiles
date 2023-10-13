---@diagnostic disable: undefined-global
return {
    s({
        trig = 'td',
        name = 'TODO',
        desc = 'TODO/NOTE/HACK comment',
        show_condition = function()
            -- Enable in normal buffers only.
            if vim.bo.buftype ~= '' then
                return false
            end

            return ts_show(function(node_type)
                return not vim.iter({ 'string', 'comment' }):any(function(name)
                    return node_type:match(name)
                end)
            end)()
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
