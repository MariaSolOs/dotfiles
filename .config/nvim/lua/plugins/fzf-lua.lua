local icons = require 'icons'

-- Custom files picker with toggling for respecting/ignoring .gitignore.
local FilesPicker = {
    opts = nil,
    ignoring = nil,
}
FilesPicker.toggle = function()
    FilesPicker.pick(FilesPicker.opts)
end
FilesPicker.pick = function(opts)
    -- Always start by respecting .gitignore (will be toggled below).
    if not opts then
        FilesPicker.ignoring = true
    end

    -- Settings to always apply.
    opts = opts or { actions = { ['ctrl-g'] = FilesPicker.toggle } }
    opts.winopts = opts.winopts or { title_pos = 'center' }
    opts.cmd = 'fd --color=never --type f --hidden --follow'

    local behavior = ''
    if FilesPicker.ignoring then
        behavior = 'respecting'
        opts.cmd = opts.cmd .. ' --exclude .git'
    else
        behavior = 'ignoring'
        opts.cmd = opts.cmd .. ' --no-ignore'
    end
    opts.winopts.title = string.format('Files (%s .gitignore)', behavior)

    FilesPicker.ignoring = not FilesPicker.ignoring
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
                        winopts = {
                            height = 0.6,
                            width = 0.5,
                            preview = { vertical = 'up:70%' },
                        },
                    }
                end,
                desc = 'Grep current buffer',
            },
            { '<leader>fc', '<cmd>FzfLua highlights<cr>', desc = 'Highlights' },
            { '<leader>fd', '<cmd>FzfLua lsp_document_diagnostics<cr>', desc = 'Document diagnostics' },
            { '<leader>fD', '<cmd>FzfLua lsp_workspace_diagnostics<cr>', desc = 'Workspace diagnostics' },
            { '<leader>ff', FilesPicker.pick, desc = 'Find files' },
            { '<leader>fg', '<cmd>FzfLua live_grep_glob<cr>', desc = 'Grep' },
            { '<leader>fh', '<cmd>FzfLua help_tags<cr>', desc = 'Help' },
            { '<leader>fr', '<cmd>FzfLua oldfiles<cr>', desc = 'Recently opened files' },
        },
        opts = {
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
                ['--layout'] = 'reverse-list',
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
                height = 0.7,
                width = 0.55,
                preview = {
                    scrollbar = false,
                    layout = 'vertical',
                    vertical = 'up:40%',
                },
            },
            global_git_icons = false,
            -- Configuration for specific commands.
            files = {
                winopts = {
                    preview = { hidden = 'hidden' },
                },
            },
            grep = {
                header_prefix = icons.misc.search .. ' ',
            },
            lsp = {
                symbols = {
                    symbol_icons = icons.symbol_kinds,
                },
            },
            oldfiles = {
                include_current_session = true,
                winopts = {
                    preview = { hidden = 'hidden' },
                },
            },
        },
        config = function(_, opts)
            require('fzf-lua').setup(opts)

            -- Add the .gitignore toggle description for the files picker.
            require('fzf-lua.config').set_action_helpstr(FilesPicker.toggle, 'no-ignore<->ignore')
        end,
    },
}
