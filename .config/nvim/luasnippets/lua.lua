---@diagnostic disable: undefined-global
return {
    postfix({
        trig = '.vp',
        name = 'Vim print',
        desc = 'Wrap in print statement',
    }, {
        f(function(_, parent)
            return string.format('vim.print(%s)', parent.snippet.env.POSTFIX_MATCH)
        end),
    }),
}
