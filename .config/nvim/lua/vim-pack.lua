local M = {}

---@class PluginSpec
---@field src string The GitHub repository of the plugin
---@field module_name? string Optional module name for configuration (defaults to the repo name)
---@field opts? table|fun():table Optional configuration options for the plugin
---@field on_setup? fun():nil Optional function to run after the plugin is loaded and configured

---@param event vim.api.keyset.events
---@param pattern? string|string[]
---@param plugins PluginSpec[]
local add_on_event = function(event, pattern, plugins)
    vim.api.nvim_create_autocmd(event, {
        pattern = pattern,
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
                local opts = type(plugin.opts) == 'function' and plugin.opts() or plugin.opts
                require(module_name).setup(opts or {})

                if plugin.on_setup then
                    plugin.on_setup()
                end
            end
        end,
    })
end

--- Helper function for adding and configuring plugins to the current session on a specific event.
---
---@param event vim.api.keyset.events
---@param plugins PluginSpec[]
function M.add_on_event(event, plugins)
    add_on_event(event, nil, plugins)
end

--- Helper function for adding and configuring plugins to the current session when a file of a specific type is first opened.
---
---@param patterns string|string[]
---@param plugins PluginSpec[]
function M.add_on_file_type(patterns, plugins)
    add_on_event('FileType', patterns, plugins)
end

--- Runs the given command inside the plugin's directory when the plugin is updated.
---
---@param plugin_name string Plugin name
---@param cmd string|fun():nil Command to run
function M.on_plugin_update(plugin_name, cmd)
    vim.api.nvim_create_autocmd('PackChanged', {
        callback = function(args)
            if args.data.spec.name == plugin_name and (args.data.kind == 'install' or args.data.kind == 'update') then
                if type(cmd) == 'string' then
                    vim.system({ cmd }, { cwd = args.data.path })
                else
                    cmd()
                end
            end
        end,
    })
end

return M
