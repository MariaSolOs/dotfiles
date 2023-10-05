---@diagnostic disable: undefined-global
return {
    s(
        {
            trig = 'plug',
            name = 'Plugin spec',
            desc = 'Neovim plugin specification',
            show_condition = function()
                local row, col = unpack(vim.api.nvim_win_get_cursor(0))
                local ok, node = pcall(vim.treesitter.get_node, { pos = { row - 1, col - 1 } })

                return ok and node and not vim.tbl_contains({ 'string_content', 'comment_content' }, node:type())
            end,
        },
        fmt(
            [[
    return {{
        {{
            '{}',
            opts = {{}}
        }}
    }}
    ]],
            {
                d(1, function()
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
            }
        )
    ),
}
