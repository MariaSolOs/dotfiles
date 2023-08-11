local function dial_manipulate(dir, mode)
    return function()
        require('dial.map').manipulate(dir, mode)
    end
end

-- Extended increment/decrement.
return {
    {
        'monaqa/dial.nvim',
        keys = {
            {
                '<C-a>',
                dial_manipulate('increment', 'normal'),
                desc = 'Increment',
            },
            {
                '<C-x>',
                dial_manipulate('decrement', 'normal'),
                desc = 'Decrement',
            },
            {
                '<C-a>',
                dial_manipulate('increment', 'visual'),
                mode = 'v',
            },
            {
                '<C-x>',
                dial_manipulate('decrement', 'visual'),
                mode = 'v',
            },
        },
        config = function()
            local dial_augend = require 'dial.augend'
            local dial_config = require 'dial.config'

            local default_group = {
                dial_augend.integer.alias.decimal_int,
                dial_augend.decimal_fraction.new {},
                dial_augend.constant.alias.bool,
                dial_augend.constant.new {
                    elements = { '&&', '||' },
                    word = false,
                    cyclic = true,
                },
                dial_augend.case.new {
                    types = { 'camelCase', 'PascalCase', 'snake_case', 'SCREAMING_SNAKE_CASE' },
                    cyclic = true,
                },
            }

            dial_config.augends:register_group { default = default_group }

            -- Extra augends for specific filetypes.
            local function filetype_group(extra)
                local group = vim.deepcopy(default_group)
                for _, augend in ipairs(extra) do
                    table.insert(group, augend)
                end
                return group
            end
            dial_config.augends:on_filetype {
                lua = filetype_group {
                    dial_augend.constant.new {
                        elements = { 'and', 'or' },
                        word = true,
                        cyclic = true,
                    },
                },
                markdown = filetype_group {
                    dial_augend.misc.alias.markdown_header,
                },
                typescript = filetype_group {
                    dial_augend.constant.new {
                        elements = { 'let', 'const', 'var' },
                        word = true,
                        cyclic = true,
                    },
                },
            }
        end,
    },
}
