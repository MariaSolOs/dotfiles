-- Popup for pending keybinds.
return {
    {
        'folke/which-key.nvim',
        event = 'VeryLazy',
        -- TODO: Update to the latest version when https://github.com/folke/which-key.nvim/issues/482 gets fixed.
        version = '1.4.3',
        opts = {
            window = { border = 'rounded' },
            disable = {
                filetypes = { 'alpha' },
            },
        },
        config = function(_, opts)
            local wk = require 'which-key'
            wk.setup(opts)

            wk.register {
                -- Register leader groups.
                ['<leader>c'] = { name = '+code' },
                ['<leader>d'] = { name = '+debug' },
                ['<leader>f'] = { name = '+finder' },
                ['<leader>x'] = { name = '+loclist/quickfix' },
                -- Other builtin prefixes.
                ['g'] = { name = '+goto' },
                ['['] = { name = '+previous' },
                [']'] = { name = '+next' },
                ['='] = { name = '+put' },
            }

            -- Register all text objects.
            local i = {
                [' '] = 'Whitespace',
                ['"'] = 'Balanced "',
                ["'"] = "Balanced '",
                ['`'] = 'Balanced `',
                ['('] = 'Balanced (',
                [')'] = 'Balanced ) including white-space',
                ['>'] = 'Balanced > including white-space',
                ['<lt>'] = 'Balanced <',
                [']'] = 'Balanced ] including white-space',
                ['['] = 'Balanced [',
                ['}'] = 'Balanced } including white-space',
                ['{'] = 'Balanced {',
                ['?'] = 'User Prompt',
                _ = 'Underscore',
                a = 'Argument',
                b = 'Balanced ), ], }',
                f = 'Function',
                q = 'Quote `, ", \'',
                t = 'Tag',
            }
            local a = vim.deepcopy(i)
            for k, v in pairs(a) do
                a[k] = v:gsub(' including.*', '')
            end

            wk.register {
                mode = { 'o', 'x' },
                i = i,
                a = a,
            }
        end,
    },
}
