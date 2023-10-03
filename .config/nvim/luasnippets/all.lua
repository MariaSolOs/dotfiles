---@diagnostic disable: undefined-global
return {
    s({
        trig = 'td',
        name = 'TODO',
        desc = 'TODO/NOTE/HACK comment',
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
