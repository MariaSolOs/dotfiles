-- Enable the experimental Lua module loader.
vim.loader.enable()

-- Global variables.
vim.g.projects_dir = vim.env.HOME .. '/Code'
vim.g.work_projects_dir = '/Volumes/git'

-- Set my colorscheme.
vim.cmd.colorscheme 'miss-dracula'

-- General setup and goodies (order matters here).
require 'settings'
require 'keymaps'
require 'commands'
require 'autocmds'
require 'statusline'
require 'winbar'
require 'marks'
require 'lsp'

-- Interactive textual undotree:
vim.cmd.packadd 'nvim.undotree'

-- Enable the new experimental command-line features.
require('vim._core.ui2').enable {}
