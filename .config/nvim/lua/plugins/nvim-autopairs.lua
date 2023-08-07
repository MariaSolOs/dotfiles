-- Autoclosing braces.
return {
    {
        'windwp/nvim-autopairs',
        event = 'InsertEnter',
        config = function()
            local npairs = require 'nvim-autopairs'
            local Rule = require 'nvim-autopairs.rule'
            local cond = require 'nvim-autopairs.conds'
            local utils = require 'nvim-autopairs.utils'

            npairs.setup()

            -- I don't really get how this works, I just copied it from https://github.com/windwp/nvim-autopairs/issues/167#issuecomment-1502559849
            -- and added some tweaks for quotes.
            local function multiline_close_jump(open, close)
                return Rule(close, '')
                    :with_pair(function()
                        local row, col = utils.get_cursor(0)
                        local line = utils.text_get_current_line(0)

                        if #line ~= col then
                            return false
                        end

                        local unclosed_count = 0
                        if open == close then
                            _, unclosed_count = line:gsub(open, '')
                            unclosed_count = unclosed_count % 2 == 1 and 0 or 1
                        else
                            for c in line:gmatch('[\\' .. open .. '\\' .. close .. ']') do
                                if c == open then
                                    unclosed_count = unclosed_count + 1
                                elseif unclosed_count > 0 and c == close then
                                    unclosed_count = unclosed_count - 1
                                end
                            end
                        end

                        if unclosed_count > 0 then
                            return false
                        end

                        local next_row = row + 1

                        return next_row < vim.api.nvim_buf_line_count(0)
                            and vim.regex('^\\s*' .. close):match_line(0, next_row)
                    end)
                    :with_move(cond.none())
                    :with_cr(cond.none())
                    :with_del(cond.none())
                    :set_end_pair_length(0)
                    :replace_endpair(function(opts)
                        local row, _ = utils.get_cursor(0)
                        local action = vim.regex('^' .. close):match_line(0, row + 1) and 'a'
                            or ('0f%sa'):format(opts.char)
                        return ('<esc>xj%s'):format(action)
                    end)
            end

            npairs.add_rules {
                multiline_close_jump('(', ')'),
                multiline_close_jump('[', ']'),
                multiline_close_jump('{', '}'),
                multiline_close_jump('<', '>'),
                multiline_close_jump("'", "'"),
                multiline_close_jump('"', '"'),
            }
        end,
    },
}
