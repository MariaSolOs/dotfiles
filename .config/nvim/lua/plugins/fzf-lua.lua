local symbol_icons = require('icons').symbol_kinds

-- Custom files picker with toggling for respecting/ignoring .gitignore.
local FilesPicker = { opts = nil }
FilesPicker.toggle = function(_, _)
    FilesPicker.pick(FilesPicker.opts)
end
FilesPicker.pick = function(opts)
    opts = opts or {}
    opts.cmd = opts.cmd or 'fd --color=never --type f --hidden --follow --no-ignore'
    opts.actions = {
        ['ctrl-g'] = FilesPicker.toggle,
    }
    local behavior = ''
    if opts.cmd:match '%s+%-%-no%-ignore$' then
        behavior = 'respecting'
        opts.cmd = opts.cmd:gsub('%s+%-%-no%-ignore$', '')
    else
        behavior = 'ignoring'
        opts.cmd = opts.cmd .. ' --no-ignore'
    end
    opts.winopts = { title = 'Files (' .. behavior .. ' .gitignore)' }
    FilesPicker.opts = opts

    require('fzf-lua').files(opts)
end

-- Picker, finder, etc.
return {
    {
        'ibhagwan/fzf-lua',
        cmd = 'FzfLua',
        keys = {
            { '<leader>f<', '<cmd>FzfLua resume<cr>', desc = 'Resume last command' },
            {
                '<leader>fb',
                function()
                    require('fzf-lua').grep_curbuf {
                        fzf_opts = {
                            ['--layout'] = 'reverse',
                        },
                        winopts = {
                            height = 0.6,
                            width = 0.5,
                            preview = {
                                layout = 'vertical',
                                vertical = 'down:70%',
                            },
                        },
                    }
                end,
                desc = 'Grep current buffer',
            },
            { '<leader>fc', '<cmd>FzfLua highlights<cr>', desc = 'Highlights' },
            { '<leader>fd', '<cmd>FzfLua lsp_workspace_diagnostics<cr>', desc = 'Diagnostics' },
            { '<leader>ff', FilesPicker.pick, desc = 'Find files' },
            { '<leader>fg', '<cmd>FzfLua live_grep<cr>', desc = 'Grep' },
            { '<leader>fh', '<cmd>FzfLua help_tags<cr>', desc = 'Help' },
            { '<leader>fr', '<cmd>FzfLua oldfiles<cr>', desc = 'Recently opened files' },
        },
        config = function()
            local fzf = require 'fzf-lua'

            -- Add the .gitignore toggle description for the files picker.
            require('fzf-lua.config').set_action_helpstr(FilesPicker.toggle, 'no-ignore<->ignore')

            fzf.setup {
                -- Make stuff better combine with the editor.
                fzf_colors = {
                    bg = { 'bg', 'Normal' },
                    gutter = { 'bg', 'Normal' },
                    info = { 'fg', 'Conditional' },
                    scrollbar = { 'bg', 'Normal' },
                    separator = { 'fg', 'Comment' },
                },
                fzf_opts = {
                    ['--info'] = 'default',
                },
                keymap = {
                    builtin = {
                        ['<C-/>'] = 'toggle-help',
                        ['<C-a>'] = 'toggle-fullscreen',
                        ['<C-i>'] = 'toggle-preview',
                        ['<C-f>'] = 'preview-page-down',
                        ['<C-b>'] = 'preview-page-up',
                    },
                    fzf = {
                        ['alt-s'] = 'toggle',
                        ['alt-a'] = 'toggle-all',
                    },
                },
                winopts = {
                    preview = { scrollbar = false },
                },
                -- Configuration for specific commands.
                files = { git_icons = false },
                oldfiles = { include_current_session = true },
                grep = {
                    git_icons = false,
                    header_prefix = ' ',
                },
                lsp = {
                    symbols = {
                        symbol_icons = symbol_icons,
                    },
                },
            }
        end,
    },
}
