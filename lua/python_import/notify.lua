M = {}

local status2, vscode = pcall(require, "vscode")
if status2 then
  ---@param message string|string[]
  M.notify = function(message, level, opts)
    if type(message) == "table" then
      message = table.concat(message, "\n")
    end
    vscode.notify(message, level)
  end
else
  local status, nvim_notify = pcall(require, "notify")
  if status then
    M.notify = nvim_notify
  end
end

if M.notify == nil then
  M.notify = function(message, level, opts) end
end

return M
