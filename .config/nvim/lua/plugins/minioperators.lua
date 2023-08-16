-- Text edit operators.
return {
    {
        'echasnovski/mini.operators',
        keys = {
            { '<leader>oe', desc = 'Evaluate' },
            { '<leader>ox', desc = 'Exchange' },
            { '<leader>om', desc = 'Multiply' },
            { '<leader>or', desc = 'Replace' },
            { '<leader>os', desc = 'Sort' },
        },
        config = function()
            local minioperators = require 'mini.operators'

            minioperators.setup {
                evaluate = { prefix = '<leader>oe' },
                exchange = { prefix = '<leader>ox' },
                multiply = { prefix = '<leader>om' },
                replace = { prefix = '<leader>or' },
                sort = {
                    prefix = '<leader>os',
                    func = function(content)
                        local opts = nil
                        if content.submode == 'v' then
                            local delimiter = vim.fn.input 'Sort delimiter: '
                            -- TODO: Word sorting? https://github.com/echasnovski/mini.nvim/issues/439#issuecomment-1681408764
                            if #delimiter > 0 then
                                opts = {
                                    split_patterns = { '%s*' .. vim.pesc(delimiter) .. '%s*' },
                                }
                            end
                        end
                        return minioperators.default_sort_func(content, opts)
                    end,
                },
            }
        end,
    },
}
