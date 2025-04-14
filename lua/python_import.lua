local config = require "python_import.config"
local lookup_table = require "python_import.lookup_table"

---In Lua, if a value in a table is set to `nil`, it is treated as if the key does not exist.
---Thus, we use `vim.NIL` in the PythonImport.UserConfig to indicate that the value should be removed from the table.
---@param t table
local function remove_vim_nil(t)
  for k, v in pairs(t) do
    if v == vim.NIL then
      t[k] = nil
    end
  end
end

local M = {}

---@class PythonImport.UserExtendLookupTable
---@field import string[]?
---@field import_as table<string, string|vim.NIL>?
---@field import_from table<string, string|vim.NIL>?
---@field statement_after_imports table<string, string[]|vim.NIL>?

---@class PythonImport.UserConfig
---@field extend_lookup_table PythonImport.UserExtendLookupTable?
---
---Return nil to indicate no match is found and continue with the default lookup
---Return a table to stop the lookup and use the returned table as the result
---Return an empty table to stop the lookup. This is useful when you want to add to wherever you need to.
---@field custom_function fun(winnr: integer, word: string, ts_node: TSNode?): string[]? | nil

---@param opts PythonImport.UserConfig
function M.setup(opts)
  -- NOTE: This may be called twice if you lazy load the plugin
  -- The first time will be with the default opts.
  -- You shouldn't assume that the setup is final. Write it so that it is reversible and can be called multiple times.
  -- e.g. when you set keymaps / autocmds, make sure to clear them.

  config.opts = vim.tbl_deep_extend("force", {}, config.default_opts, opts)

  lookup_table.import =
    vim.tbl_deep_extend("force", {}, lookup_table.default_import, config.opts.extend_lookup_table.import)
  lookup_table.import_as =
    vim.tbl_deep_extend("force", {}, lookup_table.default_import_as, config.opts.extend_lookup_table.import_as)
  lookup_table.import_from =
    vim.tbl_deep_extend("force", {}, lookup_table.default_import_from, config.opts.extend_lookup_table.import_from)
  lookup_table.statement_after_imports = vim.tbl_deep_extend(
    "force",
    {},
    lookup_table.default_statement_after_imports,
    config.opts.extend_lookup_table.statement_after_imports
  )

  remove_vim_nil(lookup_table.import_as)
  remove_vim_nil(lookup_table.import_from)
  remove_vim_nil(lookup_table.statement_after_imports)

  -- make lookup table for faster lookup
  for _, v in ipairs(lookup_table.import) do
    lookup_table.is_import[v] = true
  end
end

return M
