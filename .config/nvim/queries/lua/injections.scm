;; extends

;; Highlight vim commands embedded in lua strings.
(function_call
  name: (dot_index_expression) @cmd_ident (#any-of? @cmd_ident "vim.cmd" "vim.api.nvim_command" "vim.api.nvim_command" "vim.api.nvim_exec2")
  arguments: (arguments
    (string content: _ @injection.content))
  (#set! injection.language "vim"))
(function_call
  name: (dot_index_expression) @cmd_ident (#any-of? @cmd_ident "vim.api.nvim_create_autocmd" "vim.api.nvim_create_user_command"))
  arguments: (arguments
    (table_constructor
      (field
        name: (identifier) @field_ident (#eq? @field_ident "command")
        value: (string content: _ @injection.content)))
  (#set! injection.language "vim"))
