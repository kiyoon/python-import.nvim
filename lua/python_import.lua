local config = require "python_import.config"
local lookup_table = require "python_import.lookup_table"

local M = {}

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

  -- make lookup table for faster lookup
  for _, v in ipairs(lookup_table.import) do
    lookup_table.is_import[v] = true
  end
end

return M
