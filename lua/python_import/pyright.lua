-- Taken from https://github.com/stevanmilic/nvim-lspimport
-- Modified to work with basedpyright, and with Spanish (item.menu == "Importación automática")
-- NOTE: You need to use pyright with either English or Spanish, and enable reportUndefinedVariable.
-- TODO: Make it work with vscode. Probably add pylance source and use a proper LSP function that vscode-neovim overrides.

local M = {}

---@enum python_import.pyright.ImportStatus
M.ImportStatus = {
  RESOLVED_IMPORT = "RESOLVED_IMPORT",
  USER_ABORT = "USER_ABORT",
  NO_IMPORT = "NO_IMPORT",
  ERROR = "ERROR",
}

---@class lspimport.Server
---@field is_unresolved_import_error fun(diagnostic: vim.Diagnostic): boolean
---@field is_auto_import_completion_item fun(item: any): boolean

local function pyright_server()
  -- Reports undefined variables as unresolved imports.
  ---@param diagnostic vim.Diagnostic
  ---@return boolean
  local function is_unresolved_import_error(diagnostic)
    return diagnostic.code == "reportUndefinedVariable"
  end

  --- Returns "Auto-import" menu item as import completion.
  ---@param item any
  ---@return boolean
  local function is_auto_import_completion_item(item)
    return item.menu == "Auto-import" or item.menu == "Importación automática"
  end

  return {
    is_unresolved_import_error = is_unresolved_import_error,
    is_auto_import_completion_item = is_auto_import_completion_item,
  }
end

---Returns a server class.
---@param diagnostic vim.Diagnostic
---@return lspimport.Server|nil
function M.get_server(diagnostic)
  if diagnostic.source == "Pyright" or diagnostic.source == "basedpyright" then
    return pyright_server()
  else
    print(diagnostic.source)
  end
end

---@param winnr integer?
---@return vim.Diagnostic[]
local get_unresolved_import_errors = function(winnr)
  winnr = winnr or vim.api.nvim_get_current_win()
  local bufnr = vim.api.nvim_win_get_buf(winnr)
  local line, _ = unpack(vim.api.nvim_win_get_cursor(winnr))
  local diagnostics = vim.diagnostic.get(bufnr, { lnum = line - 1, severity = vim.diagnostic.severity.ERROR })
  if vim.tbl_isempty(diagnostics) then
    return {}
  end
  ---@param diagnostic vim.Diagnostic
  return vim.tbl_filter(function(diagnostic)
    local server = M.get_server(diagnostic)
    if server == nil then
      return false
    end
    return server.is_unresolved_import_error(diagnostic)
  end, diagnostics)
end

---@param winnr integer?
---@param diagnostics vim.Diagnostic[]
---@return vim.Diagnostic|nil
local get_diagnostic_under_cursor = function(winnr, diagnostics)
  winnr = winnr or vim.api.nvim_get_current_win()
  local cursor = vim.api.nvim_win_get_cursor(winnr)
  local row, col = cursor[1] - 1, cursor[2]
  for _, d in ipairs(diagnostics) do
    if d.lnum <= row and d.col <= col and d.end_lnum >= row and d.end_col >= col then
      return d
    end
  end
  return nil
end

---@param result vim.lsp.CompletionResult Result of `textDocument/completion`
---@param prefix string prefix to filter the completion items
---@return table[]
local lsp_to_complete_items = function(result, prefix)
  -- TODO: use another function once it's available in public API.
  -- See: https://neovim.io/doc/user/deprecated.html#vim.lsp.util.text_document_completion_list_to_complete_items()
  return vim.lsp._completion._lsp_to_complete_items(result, prefix)
end

---@param server lspimport.Server
---@param result lsp.CompletionList|lsp.CompletionItem[] Result of `textDocument/completion`
---@param unresolved_import string
---@return table[]
local get_auto_import_complete_items = function(server, result, unresolved_import)
  local items = lsp_to_complete_items(result, unresolved_import)
  if vim.tbl_isempty(items) then
    return {}
  end
  return vim.tbl_filter(function(item)
    return item.word == unresolved_import
      and item.user_data
      and item.user_data.nvim
      and item.user_data.nvim.lsp.completion_item
      and item.user_data.nvim.lsp.completion_item.labelDetails
      and item.user_data.nvim.lsp.completion_item.labelDetails.description
      and item.user_data.nvim.lsp.completion_item.additionalTextEdits
      and not vim.tbl_isempty(item.user_data.nvim.lsp.completion_item.additionalTextEdits)
      and server.is_auto_import_completion_item(item)
  end, items)
end

---@param item any|nil
---@param bufnr integer
---@return python_import.pyright.ImportStatus
local resolve_import = function(item, bufnr)
  if item == nil then
    return M.ImportStatus.NO_IMPORT
  end
  local text_edits = item.user_data.nvim.lsp.completion_item.additionalTextEdits
  vim.lsp.util.apply_text_edits(text_edits, bufnr, "utf-8")
  return M.ImportStatus.RESOLVED_IMPORT
end

-- ---@param item any
-- local format_import = function(item)
--   return item.abbr .. " " .. item.kind .. " " .. item.user_data.nvim.lsp.completion_item.labelDetails.description
-- end

---@param server lspimport.Server
---@param result lsp.CompletionList|lsp.CompletionItem[] Result of `textDocument/completion`
---@param unresolved_import string
---@param bufnr integer
---@return python_import.pyright.ImportStatus
local lsp_completion_handler = function(server, result, unresolved_import, bufnr)
  if vim.tbl_isempty(result or {}) then
    -- vim.notify("no import found for " .. unresolved_import)
    return M.ImportStatus.NO_IMPORT
  end
  local items = get_auto_import_complete_items(server, result, unresolved_import)
  if vim.tbl_isempty(items) then
    -- vim.notify("no import found for " .. unresolved_import)
    return M.ImportStatus.NO_IMPORT
  end
  if #items == 1 then
    return resolve_import(items[1], bufnr)
  else
    -- vim.ui.select(
    --   items,
    --   { prompt = "Select Import For " .. unresolved_import, format_item = format_import },
    --   function(item, _)
    --     resolved = resolve_import(item, bufnr)
    --   end
    -- )
    local outputs_to_inputlist = {}
    for i, item in ipairs(items) do
      local description = item.abbr
        .. " "
        .. item.kind
        .. " "
        .. item.user_data.nvim.lsp.completion_item.labelDetails.description
      outputs_to_inputlist[i] = string.format("%d. %s", i, description)
    end

    local choice = vim.fn.inputlist(outputs_to_inputlist)
    if choice == 0 then
      return M.ImportStatus.USER_ABORT
    end
    return resolve_import(items[choice], bufnr)
  end
end

---@param diagnostic vim.Diagnostic
---@return python_import.pyright.ImportStatus
local lsp_completion = function(diagnostic)
  local unresolved_import = vim.api.nvim_buf_get_text(
    diagnostic.bufnr,
    diagnostic.lnum,
    diagnostic.col,
    diagnostic.end_lnum,
    diagnostic.end_col,
    {}
  )
  if vim.tbl_isempty(unresolved_import) then
    -- vim.notify "cannot find diagnostic symbol"
    return M.ImportStatus.NO_IMPORT
  end
  local server = M.get_server(diagnostic)
  if server == nil then
    vim.notify "cannot find server implemantion for lsp import"
    return M.ImportStatus.ERROR
  end
  local params = {
    textDocument = vim.lsp.util.make_text_document_params(0),
    position = { line = diagnostic.lnum, character = diagnostic.end_col },
  }

  -- Wait for the completion to finish so it can return the status.
  -- TODO: I think it can be implemented with coroutine.
  local resolved
  local async_finished = false
  vim.lsp.buf_request(diagnostic.bufnr, "textDocument/completion", params, function(_, result)
    resolved = lsp_completion_handler(server, result, unresolved_import[1], diagnostic.bufnr)
    async_finished = true
  end)

  while not async_finished do
    vim.wait(100)
  end

  return resolved
end

-- M.import = function()
--   vim.schedule(function()
--     local diagnostics = get_unresolved_import_errors()
--     if vim.tbl_isempty(diagnostics) then
--       vim.notify "no unresolved import error"
--       return
--     end
--     local diagnostic = get_diagnostic_under_cursor(diagnostics)
--     lsp_completion(diagnostic or diagnostics[1])
--   end)
-- end

---Modified above so that it is not async and returns if the import is resolved.
---@param winnr integer?
---@return python_import.pyright.ImportStatus
M.import = function(winnr)
  winnr = winnr or vim.api.nvim_get_current_win()
  -- local bufnr = vim.api.nvim_win_get_buf(winnr)

  local diagnostics = get_unresolved_import_errors(winnr)
  if vim.tbl_isempty(diagnostics) then
    -- vim.notify "no unresolved import error"
    return M.ImportStatus.NO_IMPORT
  end
  local diagnostic = get_diagnostic_under_cursor(winnr, diagnostics)
  return lsp_completion(diagnostic or diagnostics[1])
end

return M
