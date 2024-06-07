local status, notify = pcall(require, "notify")
if not status then
	notify = function(message, level, opts) end
end

local lookup_table = require("python-import.lookup_table")

local function find_python_after_module_docstring(max_lines)
	max_lines = max_lines or 50
	local bufnr = vim.fn.bufnr()
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, max_lines, false)
	for i, line in ipairs(lines) do
		local node = vim.treesitter.get_node({ pos = { i - 1, 0 } })
		-- if node == nil or node:type() == "module" then
		--   local stripped = line:match "^%s*(.*)%s*$"
		--   if stripped == "" then
		--     return i
		--   end
		-- elseif node:type() == "import_statement" or node:type() == "import_from_statement" then
		--   return i
		if
			node ~= nil
			and node:type() ~= "comment"
			and node:type() ~= "string"
			and node:type() ~= "string_start"
			and node:type() ~= "string_content"
			and node:type() ~= "string_end"
		then
			return i
		end
	end
	return nil
end

local function find_first_python_import(max_lines)
	max_lines = max_lines or 50
	local bufnr = vim.fn.bufnr()
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, max_lines, false)
	for i, line in ipairs(lines) do
		local node = vim.treesitter.get_node({ pos = { i - 1, 0 } })
		if node ~= nil and (node:type() == "import_statement" or node:type() == "import_from_statement") then
			-- additional check whether the node is top-level.
			-- if not, it's probably an import inside a function
			if node:parent():type() == "module" then
				return i
			end
		end
	end
	return nil
end

local function find_last_python_import(max_lines)
	max_lines = max_lines or 50
	local bufnr = vim.fn.bufnr()
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, max_lines, false)
	-- iterate backwards
	for i = #lines, 1, -1 do
		local node = vim.treesitter.get_node({ pos = { i - 1, 0 } })
		if node ~= nil and (node:type() == "import_statement" or node:type() == "import_from_statement") then
			-- additional check whether the node is top-level.
			-- if not, it's probably an import inside a function
			if node:parent():type() == "module" then
				return i
			end
		end
	end
	return nil
end

local function find_python_first_party_modules()
	-- find src/module_name in git root

	-- local git_root = vim.fn.systemlist "git rev-parse --show-toplevel"
	local git_root = vim.fs.root(0, { ".git", "pyproject.toml" })
	if git_root == nil then
		return nil
	end

	local src_dir = git_root .. "/src"
	if vim.fn.isdirectory(src_dir) == 0 then
		return nil
	end

	local modules = {}
	local function find_modules(dir)
		local files = vim.fn.readdir(dir)
		for _, file in ipairs(files) do
			local path = dir .. "/" .. file
			local stat = vim.loop.fs_stat(path)
			if stat.type == "directory" then
				-- no egg-info
				if file:match("%.egg%-info$") == nil then
					modules[#modules + 1] = file
				end
			end
		end
	end
	find_modules(src_dir)

	if #modules == 0 then
		return nil
	end

	return modules
end

local function get_current_word()
	local line = vim.fn.getline(".")
	local col = vim.fn.col(".")
	local mode = vim.fn.mode(".")
	if mode == "i" then
		-- insert mode has cursor one char to the right
		col = col - 1
	end
	local finish = line:find("[^a-zA-Z0-9_]", col)
	-- look forward
	while finish == col do
		col = col + 1
		finish = line:find("[^a-zA-Z0-9_]", col)
	end

	if finish == nil then
		finish = #line + 1
	end
	local start = vim.fn.match(line:sub(1, col), [[\k*$]])
	return line:sub(start + 1, finish - 1)
end

local first_party_modules = find_python_first_party_modules()

---@param statement string
---@param ts_node TSNode?
---@return string[]?
local function get_python_import(statement, ts_node)
	if statement == nil then
		return nil
	end

	if ts_node ~= nil then
		-- check if currently on
		-- class Data(torch.utils.data.Dataset):
		-- then import torch.utils.data

		-- (class_definition ; [9, 0] - [10, 8]
		--   name: (identifier) ; [9, 6] - [9, 10]
		--   superclasses: (argument_list ; [9, 10] - [9, 36]
		--     (attribute ; [9, 11] - [9, 35]
		--       object: (attribute ; [9, 11] - [9, 27]
		--         object: (attribute ; [9, 11] - [9, 22]
		--           object: (identifier) ; [9, 11] - [9, 16]
		--           attribute: (identifier)) ; [9, 17] - [9, 22]
		--         attribute: (identifier)) ; [9, 23] - [9, 27]
		--       attribute: (identifier))) ; [9, 28] - [9, 35]
		--   body: (block ; [10, 4] - [10, 8]
		--     (pass_statement))) ; [10, 4] - [10, 8]

		if ts_node:type() == "identifier" then
			-- climb up until we find argument_list
			local parent = ts_node:parent()
			while parent ~= nil and parent:type() ~= "argument_list" do
				parent = parent:parent()
			end

			if parent ~= nil and parent:type() == "argument_list" then
				local superclasses_text = vim.treesitter.get_node_text(parent, 0)
				-- print(superclasses_text)  -- (torch.utils.data.Dataset)
				if superclasses_text:match("^%(torch%.utils%.data%.") then
					return { "import torch.utils.data" }
				end
			end
		end
	end

	if statement == "logger" then
		return { "import logging", "", "logger = logging.getLogger(__name__)" }
	end

	-- extend from .. import *
	if first_party_modules ~= nil then
		local first_module = first_party_modules[1]
		-- if statement ends with _DIR, import from the first module (from project import PROJECT_DIR)
		if statement:match("_DIR$") then
			return { "from " .. first_module .. " import " .. statement }
		elseif statement == "setup_logging" then
			return { "from " .. first_module .. ".utils.log import setup_logging" }
		end
	end

	if lookup_table.is_python_import[statement] then
		return { "import " .. statement }
	end

	if lookup_table.python_import_as[statement] ~= nil then
		return { "import " .. lookup_table.python_import_as[statement] .. " as " .. statement }
	end

	if lookup_table.python_import_from[statement] ~= nil then
		return { "from " .. lookup_table.python_import_from[statement] .. " import " .. statement }
	end

	-- Can't find from pre-defined tables.
	-- Search the project directory for the import statements
	-- Sorted from the most frequently used
	-- e.g. 00020:import ABCD

	local project_root = vim.fs.root(0, { ".git", "pyproject.toml" })
	if project_root ~= nil then
		local find_import_outputs = vim.api.nvim_exec(
			[[w !/usr/bin/python3 ~/.config/nvim/find_python_import_in_project.py count ']]
				.. project_root
				.. [[' ']]
				.. statement
				.. [[']],
			{ output = true }
		)

		if find_import_outputs ~= nil then
			-- strip
			find_import_outputs = find_import_outputs:gsub("^\n", "")
			-- find_import_outputs = find_import_outputs:match "^%s*(.*)%s*$"
			-- strip trailing newline
			find_import_outputs = find_import_outputs:gsub("\n$", "")
			-- find_import_outputs = find_import_outputs:match "^%s*(.*)%s*$"

			if find_import_outputs ~= "" then
				local find_import_outputs_split = vim.split(find_import_outputs, "\n")
				-- print(#find_import_outputs_split)
				if #find_import_outputs_split == 1 then
					local import_statement = { find_import_outputs_split[1]:sub(7) } -- remove the count
					return import_statement
				end

				local outputs_to_inputlist = {}
				for i, v in ipairs(find_import_outputs_split) do
					local count = tonumber(v:sub(1, 5))
					local import_statement = v:sub(7) -- remove the count

					outputs_to_inputlist[i] = string.format("%d. count %d: %s", i, count, import_statement)
				end

				local choice = vim.fn.inputlist(outputs_to_inputlist)
				if choice == 0 then
					return nil
				end

				local import_statement = find_import_outputs_split[choice]:sub(7) -- remove the count
				return { import_statement }
			end
		end
	end

	return { "import " .. statement }
end

---@param module string
---@param ts_node TSNode?
---@return integer?, string[]?
local function add_python_import(module, ts_node)
	-- strip
	module = module:match("^%s*(.*)%s*$")
	if module == "" then
		return nil
	end
	if lookup_table.ban_from_import[module] then
		return nil
	end

	local import_statements = nil
	-- prefer to add after last import
	local line_number = find_last_python_import()
	if line_number == nil then
		-- if no import, add to first empty line
		line_number = find_python_after_module_docstring()
		if line_number == nil then
			line_number = 1
		end
	else
		line_number = line_number + 1 -- add after last import
	end

	import_statements = get_python_import(module, ts_node)
	if import_statements == nil then
		notify("No import statement found or it was aborted, for `" .. module .. "`", "warn", {
			title = "Python auto import",
			on_open = function(win)
				local buf = vim.api.nvim_win_get_buf(win)
				vim.bo[buf].filetype = "markdown"
			end,
		})
		return nil, nil
	end

	vim.api.nvim_buf_set_lines(0, line_number - 1, line_number - 1, false, import_statements)

	return line_number, import_statements
end

local function add_python_import_current_word()
	local module = get_current_word()
	local node = ts_utils.get_node_at_cursor()
	-- local module = vim.fn.expand "<cword>"
	return add_python_import(module, node)
end

local function add_python_import_current_selection()
	vim.cmd([[normal! "sy]])
	local node = ts_utils.get_node_at_cursor()
	return add_python_import(vim.fn.getreg("s"), node)
end

vim.keymap.set("n", "<leader>i", function()
	local line_number, _ = add_python_import_current_word()
	if line_number ~= nil then
		vim.cmd([[normal! ]] .. line_number .. [[G0]])
	end
end, { silent = true, desc = "Add python import and move cursor" })
vim.keymap.set("x", "<leader>i", function()
	local line_number, _ = add_python_import_current_selection()
	if line_number ~= nil then
		vim.cmd([[normal! ]] .. line_number .. [[G0]])
	end
end, { silent = true, desc = "Add python import and move cursor" })

vim.keymap.set({ "n", "i" }, "<M-CR>", function()
	local line_number, import_statements = add_python_import_current_word()
	if line_number ~= nil then
		notify(import_statements, "info", {
			title = "Python import added at line " .. line_number,
			on_open = function(win)
				local buf = vim.api.nvim_win_get_buf(win)
				vim.bo[buf].filetype = "python"
			end,
		})
	end
end, { silent = true, desc = "Add python import" })
vim.keymap.set("x", "<M-CR>", function()
	local line_number, import_statements = add_python_import_current_selection()
	if line_number ~= nil then
		notify(import_statements, "info", {
			title = "Python import added at line " .. line_number,
			on_open = function(win)
				local buf = vim.api.nvim_win_get_buf(win)
				vim.bo[buf].filetype = "python"
			end,
		})
	end
end, { silent = true, desc = "Add python import" })

vim.keymap.set({ "n" }, "<space>tr", function()
	local statements = { "import rich.traceback", "", "rich.traceback.install(show_locals=True)", "" }

	local line_number = find_first_python_import() ---@type integer | nil

	if line_number == nil then
		line_number = find_python_after_module_docstring()
		if line_number == nil then
			line_number = 1
		end
	else
		-- first import found. Check if rich traceback already installed
		local lines = vim.api.nvim_buf_get_lines(0, line_number - 1, line_number - 1 + 3, false)
		if lines[1] == statements[1] and lines[2] == statements[2] and lines[3] == statements[3] then
			notify("Rich traceback already installed", "info", {
				title = "Python auto import",
			})
			return
		end
	end

	vim.api.nvim_buf_set_lines(0, line_number - 1, line_number - 1, false, statements)
	notify(statements, "info", {
		title = "Rich traceback install added at line " .. line_number,
		on_open = function(win)
			local buf = vim.api.nvim_win_get_buf(win)
			vim.bo[buf].filetype = "python"
		end,
	})
end, { silent = true, desc = "Add rich traceback install" })

M = {}

return M
