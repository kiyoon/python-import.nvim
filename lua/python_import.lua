local config = require("python_import.config")

local M = {}

---@param opts PythonImport.UserConfig
function M.setup(opts)
	-- NOTE: This may be called twice if you lazy load the plugin
	-- The first time will be with the default opts.
	-- You shouldn't assume that the setup is final. Write it so that it is reversible and can be called multiple times.
	-- e.g. when you set keymaps / autocmds, make sure to clear them.

	config.opts = vim.tbl_deep_extend("force", {}, config.default_opts, opts)
end

return M
