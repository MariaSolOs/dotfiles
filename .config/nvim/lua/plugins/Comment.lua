-- 'gc' to comment visual regions/lines.
return {
    {
        'numToStr/Comment.nvim',
        config = true,
        keys = {
            { 'gcc', desc = 'Toggle line comment' },
            { 'gc', mode = { 'n', 'x' }, desc = 'Toggle comment' },
            -- Comment text object. Taken from https://github.com/numToStr/Comment.nvim/issues/22#issuecomment-1272569139
            {
                'gc',
                function()
                    local utils = require 'Comment.utils'

                    local row = vim.api.nvim_win_get_cursor(0)[1]

                    local comment_str = require('Comment.ft').calculate {
                        ctype = utils.ctype.linewise,
                        range = {
                            srow = row,
                            scol = 0,
                            erow = row,
                            ecol = 0,
                        },
                        cmotion = utils.cmotion.line,
                        cmode = utils.cmode.toggle,
                    } or vim.bo.commentstring
                    local l_comment_str, r_comment_str = utils.unwrap_cstr(comment_str)

                    local is_commented = utils.is_commented(l_comment_str, r_comment_str, true)

                    local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)
                    if next(line) == nil or not is_commented(line[1]) then
                        return
                    end

                    local comment_start, comment_end = row, row
                    repeat
                        comment_start = comment_start - 1
                        line = vim.api.nvim_buf_get_lines(0, comment_start - 1, comment_start, false)
                    until next(line) == nil or not is_commented(line)
                    comment_start = comment_start + 1
                    repeat
                        comment_end = comment_end + 1
                        line = vim.api.nvim_buf_get_lines(0, comment_end - 1, comment_end, false)
                    until next(line) == nil or not is_commented(line)
                    comment_end = comment_end - 1

                    vim.cmd(string.format('normal! %dGV%dG', comment_start, comment_end))
                end,
                mode = 'o',
                desc = 'Comment',
            },
        },
    },
}
