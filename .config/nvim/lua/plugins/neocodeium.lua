-- AI completions.
return {
    {
        'monkoose/neocodeium',
        event = 'InsertEnter',
        opts = {
            server = {
                api_url = 'https://windsurf.fedstart.com/_route/api_server',
                portal_url = 'https://windsurf.fedstart.com',
            },
            -- Don't show the number of suggestions in the gutter.
            show_label = false,
        },
        keys = {
            {
                '<C-.>',
                function()
                    require('neocodeium').accept()
                end,
                desc = 'Accept AI suggestion',
                mode = 'i',
            },
            {
                '<M-w>',
                function()
                    require('neocodeium').accept_word()
                end,
                desc = 'Accept AI suggestion word',
                mode = 'i',
            },
            {
                '<M-l>',
                function()
                    require('neocodeium').accept_line()
                end,
                desc = 'Accept AI suggestion line',
                mode = 'i',
            },
        },
    },
}
