local lookup_table = require "python_import.lookup_table"
local ts_utils = require "python_import.ts_utils"
local health = require "python_import.health"
local utils = require "python_import.utils"
local config = require "python_import.config"
local pyright = require "python_import.pyright"
local notify = require("python_import.notify").notify

M = {}

---@param winnr integer
---@param word string
---@param ts_node TSNode?
---@return string[]?
local function get_import(winnr, word, ts_node)
  winnr = winnr or vim.api.nvim_get_current_win()
  local bufnr = vim.api.nvim_win_get_buf(winnr)

  if word == nil then
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
        if superclasses_text:match "^%(torch%.utils%.data%." then
          return { "import torch.utils.data" }
        end
      end
    end
  end

  local import_statements = config.opts.custom_function(winnr, word, ts_node)
  if import_statements ~= nil then
    return import_statements
  end

  if lookup_table.statement_after_imports[word] ~= nil then
    return lookup_table.statement_after_imports[word]
  end

  if lookup_table.is_import[word] then
    return { "import " .. word }
  end

  if lookup_table.import_as[word] ~= nil then
    return { "import " .. lookup_table.import_as[word] .. " as " .. word }
  end

  if lookup_table.import_from[word] ~= nil then
    return { "from " .. lookup_table.import_from[word] .. " import " .. word }
  end

  -- Can't find from pre-defined tables.
  -- Search the project directory for the import statements
  -- Sorted from the most frequently used
  -- e.g. 00020:import ABCD

  local requirements_installed = health.is_python_cli_installed()

  if requirements_installed then
    local project_root = vim.fs.root(bufnr, { ".git", "pyproject.toml" })
    if project_root ~= nil then
      local response = vim.system({ "python-import", "count", project_root, word }, { text = true }):wait()
      if response.code == 0 then
        local find_import_outputs = response.stdout:gsub("\n$", "")

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

  -- Last resort: use pyright LSP completion.
  -- This does not work well for me, so I put it last.
  local prev_buf_str = utils.notify_diff_pre(bufnr)
  local import_status = pyright.import(winnr)
  if import_status == pyright.ImportStatus.RESOLVED_IMPORT then
    utils.notify_diff(bufnr, prev_buf_str, "python-import resolved import using pyright")
    return {} -- no further adding lines to buffer needed
  elseif import_status == pyright.ImportStatus.USER_ABORT then
    return {} -- no further adding lines to buffer needed
  end

  return { "import " .. word }
end

---@param winnr integer
---@param word string
---@param ts_node TSNode?
---@return integer?, string[]?
local function add_import(winnr, word, ts_node)
  winnr = winnr or vim.api.nvim_get_current_win()
  local bufnr = vim.api.nvim_win_get_buf(winnr)

  -- strip
  word = word:match "^%s*(.*)%s*$"
  if word == "" then
    return nil, nil
  end
  if lookup_table.ban_from_import[word] then
    return nil, nil
  end

  local import_statements = get_import(winnr, word, ts_node)
  if import_statements == nil then
    notify("No import statement found or it was aborted, for `" .. word .. "`", "warn", {
      title = "Python auto import",
      on_open = function(win)
        local buf = vim.api.nvim_win_get_buf(win)
        vim.bo[buf].filetype = "markdown"
      end,
    })
    return nil, nil
  elseif #import_statements == 0 then
    return nil, nil
  end

  -- prefer to add after last import
  local line_number = utils.find_line_last_import(bufnr)
  if line_number == nil then
    -- if no import, add to first empty line
    line_number = utils.find_line_after_module_docstring(bufnr)
    if line_number == nil then
      line_number = 1
    end
  else
    line_number = line_number + 1 -- add after last import
  end

  vim.api.nvim_buf_set_lines(bufnr, line_number - 1, line_number - 1, false, import_statements)

  return line_number, import_statements
end

---@param winnr integer?
local function add_import_current_word(winnr)
  winnr = winnr or vim.api.nvim_get_current_win()
  local module = utils.get_current_word(winnr)
  local node = ts_utils.get_node_at_cursor(winnr)

  return add_import(winnr, module, node)
end

---@param winnr integer?
local function add_import_current_selection(winnr)
  winnr = winnr or vim.api.nvim_get_current_win()

  vim.api.nvim_win_call(winnr, function()
    vim.cmd [[normal! "sy]]
  end)

  local node = ts_utils.get_node_at_cursor(winnr)
  return add_import(winnr, vim.fn.getreg "s", node)
end

-- vim.keymap.set("n", "<leader>i",
-- , { silent = true, desc = "Add python import and move cursor" })
---@param winnr integer?
M.add_import_current_word_and_move_cursor = function(winnr)
  winnr = winnr or vim.api.nvim_get_current_win()
  local line_number, _ = add_import_current_word(winnr)
  if line_number ~= nil then
    vim.api.nvim_win_call(winnr, function()
      vim.cmd([[normal! ]] .. line_number .. [[G0]])
    end)
  end
end

-- vim.keymap.set("x", "<leader>i",
-- , { silent = true, desc = "Add python import and move cursor" })
---@param winnr integer?
M.add_import_current_selection_and_move_cursor = function(winnr)
  winnr = winnr or vim.api.nvim_get_current_win()
  local line_number, _ = add_import_current_selection(winnr)
  if line_number ~= nil then
    vim.api.nvim_win_call(winnr, function()
      vim.cmd([[normal! ]] .. line_number .. [[G0]])
    end)
  end
end

-- vim.keymap.set({ "n", "i" }, "<M-CR>",
-- , { silent = true, desc = "Add python import" })

---@param winnr integer?
M.add_import_current_word_and_notify = function(winnr)
  winnr = winnr or vim.api.nvim_get_current_win()

  local line_number, import_statements = add_import_current_word(winnr)
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
---@param winnr integer?
M.add_import_current_selection_and_notify = function(winnr)
  winnr = winnr or vim.api.nvim_get_current_win()

  local line_number, import_statements = add_import_current_selection(winnr)
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
---@param winnr integer?
M.add_rich_traceback = function(winnr)
  winnr = winnr or vim.api.nvim_get_current_win()
  local bufnr = vim.api.nvim_win_get_buf(winnr)

  local statements = { "import rich.traceback", "", "rich.traceback.install(show_locals=True)", "" }

  local line_number = utils.find_line_first_import(bufnr) ---@type integer | nil

  if line_number == nil then
    line_number = utils.find_line_after_module_docstring(bufnr)
    if line_number == nil then
      line_number = 1
    end
  else
    -- first import found. Check if rich traceback already installed
    local lines = vim.api.nvim_buf_get_lines(bufnr, line_number - 1, line_number - 1 + 3, false)
    if lines[1] == statements[1] and lines[2] == statements[2] and lines[3] == statements[3] then
      notify("Rich traceback already installed", "info", {
        title = "Python auto import",
      })
      return
    end
  end

  vim.api.nvim_buf_set_lines(bufnr, line_number - 1, line_number - 1, false, statements)
  notify(statements, "info", {
    title = "Rich traceback install added at line " .. line_number,
    on_open = function(win)
      local buf = vim.api.nvim_win_get_buf(win)
      vim.bo[buf].filetype = "python"
    end,
  })
end

return M
