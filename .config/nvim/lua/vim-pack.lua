local M = {}

---@class PluginSpec
---@field src string The GitHub repository of the plugin
---@field module_name? string Optional module name for configuration (defaults to the repo name)
---@field opts? table Optional configuration options for the plugin
---@field on_setup? fun():nil Optional function to run after the plugin is loaded and configured

--- Helper function for adding and configuring plugins to the current session on a specific event.
---
---@param event vim.api.keyset.events
---@param plugins PluginSpec[]
function M.add_on_event(event, plugins)
    vim.api.nvim_create_autocmd(event, {
        once = true,
        callback = function()
            local sources = vim.iter(plugins)
                :map(function(plugin)
                    -- Ensure we use GitHub urls.
                    return string.format('https://github.com/%s', plugin.src)
                end)
                :totable()
            vim.pack.add(sources)

            -- Configure each plugin after loading.
            for _, plugin in ipairs(plugins) do
                local module_name = plugin.module_name or plugin.src:match '.+/(.+)'
                require(module_name).setup(plugin.opts or {})

                if plugin.on_setup then
                    plugin.on_setup()
                end
            end
        end,
    })
end

return M
