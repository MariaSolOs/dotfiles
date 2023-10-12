---@diagnostic disable: undefined-global
return {
    postfix({
        trig = '.vp',
        name = 'Vim print',
        desc = 'Wrap in print statement',
        show_condition = ts_show(function(node_type)
            return not vim.tbl_contains({ 'string_content', 'comment_content' }, node_type)
        end),
    }, {
        f(function(_, parent)
            return string.format('vim.print(%s)', parent.snippet.env.POSTFIX_MATCH)
        end),
    }),
}
