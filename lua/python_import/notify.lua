local notify
local status2, vscode = pcall(require, "vscode")
if status2 then
  notify = function(message, level, opts)
    vscode.notify(message)
  end
else
  local status, nvim_notify = pcall(require, "notify")
  if status then
    notify = nvim_notify.notify
  end
end

if notify == nil then
  notify = function(message, level, opts) end
end
