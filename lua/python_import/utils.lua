local notify = require("python_import.notify").notify

M = {}

---Return line after the first comments and docstring.
---It iterates e.g. 50 first lines and obtains treesitter nodes to check the syntax (string or comment)
---@param bufnr integer?
---@param max_lines integer?
---@return integer?
function M.find_line_after_module_docstring(bufnr, max_lines)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  max_lines = max_lines or 200

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, max_lines, false)
  for i, line in ipairs(lines) do
    local node = vim.treesitter.get_node { pos = { i - 1, 0 } }
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
---@param bufnr integer?
---@param max_lines integer?
function M.find_line_first_import(bufnr, max_lines)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  max_lines = max_lines or 200

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, max_lines, false)
  for i, line in ipairs(lines) do
    local node = vim.treesitter.get_node { pos = { i - 1, 0 } }
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
---@param bufnr integer?
---@param max_lines integer?
function M.find_line_last_import(bufnr, max_lines)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  max_lines = max_lines or 200

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, max_lines, false)
  -- iterate backwards
  for i = #lines, 1, -1 do
    local node = vim.treesitter.get_node { pos = { i - 1, 0 } }
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
        if file:match "%.egg%-info$" == nil then
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
---@param winnr integer?
---@return string
function M.get_current_word(winnr)
  winnr = winnr or vim.api.nvim_get_current_win()
  local bufnr = vim.api.nvim_win_get_buf(winnr)

  -- local line = vim.fn.getline "."
  -- local col = vim.fn.col "."
  -- local mode = vim.fn.mode "."
  local line, col, mode
  vim.api.nvim_win_call(winnr, function()
    line = vim.fn.getline "."
    col = vim.fn.col "."
    mode = vim.fn.mode "."
  end)

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

function M.get_cached_first_party_modules(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  if buf_to_first_party_modules[bufnr] == nil then
    buf_to_first_party_modules[bufnr] = find_python_first_party_modules(bufnr)
  end

  return buf_to_first_party_modules[bufnr]
end

function M.notify_diff_pre(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local prev_buf = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local prev_buf_str = table.concat(prev_buf, "\n")
  return prev_buf_str
end

function M.notify_diff(bufnr, prev_buf_str)
  local new_buf = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local new_buf_str = table.concat(new_buf, "\n")
  local diff = vim.diff(prev_buf_str, new_buf_str, { ctxlen = 3 })
  -- strip last empty line
  -- diff = vim.split(diff, "\n")
  -- table.remove(diff, #diff)
  -- diff = table.concat(diff, "\n")
  diff = diff:gsub("\n$", "")

  notify(diff, "info", {
    title = "python-import",
    on_open = function(win)
      local buf = vim.api.nvim_win_get_buf(win)
      vim.bo[buf].filetype = "diff"
    end,
  })
end

return M
