local status, notify = pcall(require, "notify")
if not status then
	notify = function(message, level, opts) end
end

local lookup_table = require("python_import.lookup_table")
local ts_utils = require("python_import.ts_utils")
local health = require("python_import.health")

M = {}

---Return line after the first comments and docstring.
---It iterates e.g. 50 first lines and obtains treesitter nodes to check the syntax (string or comment)
---@param max_lines integer?
---@return integer?
local function find_line_after_module_docstring(max_lines)
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

---Find the first import statement in a python file.
---@param max_lines integer?
local function find_line_first_import(max_lines)
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

---Find the last import statement in a python file.
---@param max_lines integer?
local function find_line_last_import(max_lines)
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

---Find src/module_name in git root
---@param bufnr integer?
---@return string[]?
local function find_python_first_party_modules(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	-- local git_root = vim.fn.systemlist "git rev-parse --show-toplevel"
	local git_root = vim.fs.root(bufnr, { ".git", "pyproject.toml" })
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

---Get current word in a buffer
---It is aware of the insert mode (move column by -1 if the mode is insert).
---@return string
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

local buf_to_first_party_modules = {}

local function get_cached_first_party_modules(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()

	if buf_to_first_party_modules[bufnr] == nil then
		buf_to_first_party_modules[bufnr] = find_python_first_party_modules(bufnr)
	end

	return buf_to_first_party_modules[bufnr]
end

---@param bufnr integer
---@param statement string
---@param ts_node TSNode?
---@return string[]?
local function get_import(bufnr, statement, ts_node)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
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
	if get_cached_first_party_modules(bufnr) ~= nil then
		local first_module = get_cached_first_party_modules(bufnr)[1]
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

	local requirements_installed = health.is_python_cli_installed()

	if requirements_installed then
		local project_root = vim.fs.root(0, { ".git", "pyproject.toml" })
		if project_root ~= nil then
			local find_import_outputs = vim.api.nvim_exec(
				[[w !python-import count ']] .. project_root .. [[' ']] .. statement .. [[']],
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
	end

	return { "import " .. statement }
end

---@param bufnr integer
---@param module string
---@param ts_node TSNode?
---@return integer?, string[]?
local function add_import(bufnr, module, ts_node)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
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
	local line_number = find_line_last_import()
	if line_number == nil then
		-- if no import, add to first empty line
		line_number = find_line_after_module_docstring()
		if line_number == nil then
			line_number = 1
		end
	else
		line_number = line_number + 1 -- add after last import
	end

	import_statements = get_import(bufnr, module, ts_node)
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

---@param winnr integer?
local function add_import_current_word(winnr)
	winnr = winnr or vim.api.nvim_get_current_win()
	local bufnr = vim.api.nvim_win_get_buf(winnr)

	local module = get_current_word()
	local node = ts_utils.get_node_at_cursor(winnr)
	-- local module = vim.fn.expand "<cword>"
	return add_import(bufnr, module, node)
end

local function add_import_current_selection()
	vim.cmd([[normal! "sy]])
	local node = ts_utils.get_node_at_cursor()
	return add_import(0, vim.fn.getreg("s"), node)
end

-- vim.keymap.set("n", "<leader>i",
-- , { silent = true, desc = "Add python import and move cursor" })
M.add_import_current_word_and_move_cursor = function()
	local line_number, _ = add_import_current_word()
	if line_number ~= nil then
		vim.cmd([[normal! ]] .. line_number .. [[G0]])
	end
end

-- vim.keymap.set("x", "<leader>i",
-- , { silent = true, desc = "Add python import and move cursor" })
M.add_import_current_selection_and_move_cursor = function()
	local line_number, _ = add_import_current_selection()
	if line_number ~= nil then
		vim.cmd([[normal! ]] .. line_number .. [[G0]])
	end
end

-- vim.keymap.set({ "n", "i" }, "<M-CR>",
-- , { silent = true, desc = "Add python import" })

M.add_import_current_word_and_notify = function()
	local line_number, import_statements = add_import_current_word()
	if line_number ~= nil then
		notify(import_statements, "info", {
			title = "Python import added at line " .. line_number,
			on_open = function(win)
				local buf = vim.api.nvim_win_get_buf(win)
				vim.bo[buf].filetype = "python"
			end,
		})
	end
end

-- vim.keymap.set("x", "<M-CR>",
-- , { silent = true, desc = "Add python import" })
M.add_import_current_selection_and_notify = function()
	local line_number, import_statements = add_import_current_selection()
	if line_number ~= nil then
		notify(import_statements, "info", {
			title = "Python import added at line " .. line_number,
			on_open = function(win)
				local buf = vim.api.nvim_win_get_buf(win)
				vim.bo[buf].filetype = "python"
			end,
		})
	end
end

-- vim.keymap.set({ "n" }, "<space>tr",
-- , { silent = true, desc = "Add rich traceback install" })
M.add_rich_traceback = function()
	local statements = { "import rich.traceback", "", "rich.traceback.install(show_locals=True)", "" }

	local line_number = find_line_first_import() ---@type integer | nil

	if line_number == nil then
		line_number = find_line_after_module_docstring()
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
end

return M
