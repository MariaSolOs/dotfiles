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
                ['<leader>b'] = { name = '+buffer' },
                ['<leader>c'] = { name = '+code' },
                ['<leader>d'] = { name = '+debug' },
                ['<leader>da'] = { name = '+debug adapters' },
                ['<leader>m'] = { name = '+marks' },
                ['<leader>t'] = { name = '+telescope' },
                ['<leader>x'] = { name = '+trouble' },
            }

            -- register all text objects.
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
                c = 'Class',
                f = 'Function',
                o = 'Block, conditional, loop',
                q = 'Quote `, ", \'',
                t = 'Tag',
            }
            local a = vim.deepcopy(i)
            for k, v in pairs(a) do
                a[k] = v:gsub(' including.*', '')
            end

            local ic = vim.deepcopy(i)
            local ac = vim.deepcopy(a)
            for key, name in pairs { n = 'Next', l = 'Last' } do
                ---@diagnostic disable-next-line: assign-type-mismatch
                i[key] = vim.tbl_extend('force', { name = 'Inside ' .. name .. ' textobject' }, ic)
                ---@diagnostic disable-next-line: assign-type-mismatch
                a[key] = vim.tbl_extend('force', { name = 'Around ' .. name .. ' textobject' }, ac)
            end

            wk.register {
                mode = { 'o', 'x' },
                i = i,
                a = a,
            }
        end,
    },
}
