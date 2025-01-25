local icons = require 'icons'

-- Diffs for git revisions.
return {
    {
        'sindrets/diffview.nvim',
        keys = {
            { '<leader>gf', '<cmd>DiffviewFileHistory<cr>', desc = 'File history' },
            { '<leader>gd', '<cmd>DiffviewOpen<cr>', desc = 'Diff view' },
        },
        opts = function()
            local actions = require 'diffview.actions'

            require('diffview.ui.panel').Panel.default_config_float.border = 'rounded'

            return {
                default_args = { DiffviewFileHistory = { '%' } },
                icons = {
                    folder_closed = icons.symbol_kinds.Folder,
                    folder_open = '󰝰',
                },
                signs = {
                    fold_closed = icons.arrows.right,
                    fold_open = icons.arrows.down,
                    done = '',
                },
                hooks = {
                    diff_buf_read = function(bufnr)
                        -- Register the leader group with miniclue.
                        vim.b[bufnr].miniclue_config = {
                            clues = {
                                { mode = 'n', keys = '<leader>G', desc = '+diffview' },
                            },
                        }
                    end,
                },
                -- stylua: ignore start
                keymaps = {
                    -- Easier to just configure what I need.
                    disable_defaults = true,
                    view = {
                        { 'n', '<tab>',      actions.select_next_entry,             { desc = 'Open the diff for the next file' } },
                        { 'n', '<s-tab>',    actions.select_prev_entry,             { desc = 'Open the diff for the previous file' } },
                        { 'n', '[F',         actions.select_first_entry,            { desc = 'Open the diff for the first file' } },
                        { 'n', ']F',         actions.select_last_entry,             { desc = 'Open the diff for the last file' } },
                        { 'n', '[x',         actions.prev_conflict,                 { desc = 'Merge-tool: jump to the previous conflict' } },
                        { 'n', ']x',         actions.next_conflict,                 { desc = 'Merge-tool: jump to the next conflict' } },
                        { 'n', 'gf',         actions.goto_file_tab,                 { desc = 'Open the file in a new tabpage' } },
                        { 'n', '<leader>Go', actions.conflict_choose('ours'),       { desc = 'Choose the OURS version of a conflict' } },
                        { 'n', '<leader>Gt', actions.conflict_choose('theirs'),     { desc = 'Choose the THEIRS version of a conflict' } },
                        { 'n', '<leader>Gb', actions.conflict_choose('base'),       { desc = 'Choose the BASE version of a conflict' } },
                        { 'n', '<leader>Ga', actions.conflict_choose('all'),        { desc = 'Choose all the versions of a conflict' } },
                        { 'n', '<leader>Gd', actions.conflict_choose('none'),       { desc = 'Delete the conflict region' } },
                        { 'n', '<leader>GO', actions.conflict_choose_all('ours'),   { desc = 'Choose the OURS version of a conflict for the whole file' } },
                        { 'n', '<leader>GT', actions.conflict_choose_all('theirs'), { desc = 'Choose the THEIRS version of a conflict for the whole file' } },
                        { 'n', '<leader>GB', actions.conflict_choose_all('base'),   { desc = 'Choose the BASE version of a conflict for the whole file' } },
                        unpack(actions.compat.fold_cmds),
                    },
                    diff2 = {
                        { 'n', '?', actions.help { 'view', 'diff2' }, { desc = 'Open the help panel' } },
                    },
                    diff3 = {
                        { 'n', '?', actions.help { 'view', 'diff3' }, { desc = 'Open the help panel' } },
                    },
                    file_panel = {
                        { 'n', 'j',          actions.next_entry,                    { desc = 'Bring the cursor to the next file entry' } },
                        { 'n', 'k',          actions.prev_entry,                    { desc = 'Bring the cursor to the previous file entry' } },
                        { 'n', '<cr>',       actions.select_entry,                  { desc = 'Open the diff for the selected entry' } },
                        { 'n', 's',          actions.toggle_stage_entry,            { desc = 'Stage / unstage the selected entry' } },
                        { 'n', 'S',          actions.stage_all,                     { desc = 'Stage all entries' } },
                        { 'n', 'U',          actions.unstage_all,                   { desc = 'Unstage all entries' } },
                        { 'n', 'X',          actions.restore_entry,                 { desc = 'Restore entry to the state on the left side' } },
                        { 'n', 'L',          actions.open_commit_log,               { desc = 'Open the commit log panel' } },
                        { 'n', 'gf',         actions.goto_file_tab,                 { desc = 'Open the file in a new tabpage' } },
                        { 'n', 'za',         actions.toggle_fold,                   { desc = 'Toggle fold' } },
                        { 'n', 'zR',         actions.open_all_folds,                { desc = 'Expand all folds' } },
                        { 'n', 'zM',         actions.close_all_folds,               { desc = 'Collapse all folds' } },
                        { 'n', '<c-b>',      actions.scroll_view(-0.25),            { desc = 'Scroll the view up' } },
                        { 'n', '<c-f>',      actions.scroll_view(0.25),             { desc = 'Scroll the view down' } },
                        { 'n', '<tab>',      actions.select_next_entry,             { desc = 'Open the diff for the next file' } },
                        { 'n', '<s-tab>',    actions.select_prev_entry,             { desc = 'Open the diff for the previous file' } },
                        { 'n', '[F',         actions.select_first_entry,            { desc = 'Open the diff for the first file' } },
                        { 'n', ']F',         actions.select_last_entry,             { desc = 'Open the diff for the last file' } },
                        { 'n', 'i',          actions.listing_style,                 { desc = 'Toggle between "list" and "tree" views' } },
                        { 'n', '[x',         actions.prev_conflict,                 { desc = 'Go to the previous conflict' } },
                        { 'n', ']x',         actions.next_conflict,                 { desc = 'Go to the next conflict' } },
                        { 'n', '?',          actions.help('file_panel'),            { desc = 'Open the help panel' } },
                        { 'n', '<leader>GO', actions.conflict_choose_all('ours'),   { desc = 'Choose the OURS version of a conflict for the whole file' } },
                        { 'n', '<leader>GT', actions.conflict_choose_all('theirs'), { desc = 'Choose the THEIRS version of a conflict for the whole file' } },
                        { 'n', '<leader>GB', actions.conflict_choose_all('base'),   { desc = 'Choose the BASE version of a conflict for the whole file' } },
                        { 'n', '<leader>GA', actions.conflict_choose_all('all'),    { desc = 'Choose all the versions of a conflict for the whole file' } },
                        { 'n', '<leader>GD', actions.conflict_choose_all('none'),   { desc = 'Delete the conflict region for the whole file' } },
                    },
                    file_history_panel = {
                        { 'n', '!',         actions.options,                    { desc = 'Open the option panel' } },
                        { 'n', '<leader>d', actions.open_in_diffview,           { desc = 'Open the entry under the cursor in a diffview' } },
                        { 'n', 'y',         actions.copy_hash,                  { desc = 'Copy the commit hash of the entry under the cursor' } },
                        { 'n', 'L',         actions.open_commit_log,            { desc = 'Show commit details' } },
                        { 'n', 'X',         actions.restore_entry,              { desc = 'Restore file to the state from the selected entry' } },
                        { 'n', 'za',        actions.toggle_fold,                { desc = 'Toggle fold' } },
                        { 'n', 'zR',        actions.open_all_folds,             { desc = 'Expand all folds' } },
                        { 'n', 'zM',        actions.close_all_folds,            { desc = 'Collapse all folds' } },
                        { 'n', 'j',         actions.next_entry,                 { desc = 'Bring the cursor to the next file entry' } },
                        { 'n', 'k',         actions.prev_entry,                 { desc = 'Bring the cursor to the previous file entry' } },
                        { 'n', '<cr>',      actions.select_entry,               { desc = 'Open the diff for the selected entry' } },
                        { 'n', '<c-b>',     actions.scroll_view(-0.25),         { desc = 'Scroll the view up' } },
                        { 'n', '<c-f>',     actions.scroll_view(0.25),          { desc = 'Scroll the view down' } },
                        { 'n', '<tab>',     actions.select_next_entry,          { desc = 'Open the diff for the next file' } },
                        { 'n', '<s-tab>',   actions.select_prev_entry,          { desc = 'Open the diff for the previous file' } },
                        { 'n', '[F',        actions.select_first_entry,         { desc = 'Open the diff for the first file' } },
                        { 'n', ']F',        actions.select_last_entry,          { desc = 'Open the diff for the last file' } },
                        { 'n', 'gf',        actions.goto_file_tab,              { desc = 'Open the file in a new tabpage' } },
                        { 'n', '?',         actions.help('file_history_panel'), { desc = 'Open the help panel' } },
                    },
                    option_panel = {
                        { 'n', '<tab>', actions.select_entry,         { desc = 'Change the current option' } },
                        { 'n', 'q',     actions.close,                { desc = 'Close the panel' } },
                        { 'n', '?',     actions.help('option_panel'), { desc = 'Open the help panel' } },
                    },
                    help_panel = {
                        { 'n', 'q', actions.close, { desc = 'Close help menu' } },
                    },
                },
                -- stylua: ignore end
            }
        end,
    },
}
