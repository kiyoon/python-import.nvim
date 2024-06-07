local M = {}

function M.check()
	vim.health.start("python-import")

	if vim.fn.has("nvim-0.10.0") == 1 then
		vim.health.ok("Using Neovim >= 0.10.0")
	else
		vim.health.error("Neovim >= 0.10.0 is required")
	end

	for _, cmd in ipairs({ "rg", "fd", "python-import" }) do
		if vim.fn.executable(cmd) == 1 then
			vim.health.ok(("`%s` is installed"):format(cmd))
		else
			vim.health.error(("`%s` is not installed"):format(cmd))
		end
	end
end

---@return boolean
function M.is_python_cli_installed()
	for _, cmd in ipairs({ "rg", "fd", "python-import" }) do
		if vim.fn.executable(cmd) ~= 1 then
			return false
		end
	end

	return true
end

return M
