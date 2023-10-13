---@diagnostic disable: undefined-global
return {
    s(
        {
            trig = 'plug',
            name = 'Plugin spec',
            desc = 'Neovim plugin specification',
            show_condition = ts_show(function(node_type)
                return not vim.tbl_contains({ 'string_content', 'comment_content' }, node_type)
            end),
        },
        fmt(
            [[
    -- {1}
    return {{
        {{
            '{2}',
            opts = {{{3}}}
        }}
    }}
    ]],
            {
                i(1),
                d(2, function()
                    -- Try to use the clipboard to get the plugin's URL.
                    local author, plugin = 'author', 'plugin'
                    local clipboard = vim.fn.getreg '+'
                    ---@cast clipboard string
                    local parts = vim.split(clipboard, '/')
                    if vim.startswith(clipboard, 'https://github.com/') and #parts >= 2 then
                        author, plugin = parts[#parts - 1], parts[#parts]
                    end

                    return sn(nil, { t(author .. '/' .. plugin) })
                end),
                i(3),
            }
        )
    ),
}
