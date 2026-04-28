local add_on_event = require('vim-pack').add_on_event

-- AI completions.
add_on_event('InsertEnter', {
    {
        src = 'monkoose/neocodeium',
        opts = function()
            local opts = {
                -- Don't show the number of suggestions in the gutter.
                show_label = false,
            }

            -- Configure the server for work.
            if vim.startswith(vim.fn.hostname(), 'msolano') then
                opts.server = {
                    api_url = 'https://windsurf.fedstart.com/_route/api_server',
                    portal_url = 'https://windsurf.fedstart.com',
                }
            end

            return opts
        end,
        on_setup = function()
            vim.keymap.set('i', '<C-.>', function()
                require('neocodeium').accept()
            end, { desc = 'Accept AI suggestion' })
            vim.keymap.set('i', '<M-w>', function()
                require('neocodeium').accept_word()
            end, { desc = 'Accept AI suggestion word' })
            vim.keymap.set('i', '<M-l>', function()
                require('neocodeium').accept_line()
            end, { desc = 'Accept AI suggestion line' })
        end,
    },
})
