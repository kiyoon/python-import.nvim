local function script_path()
  return debug.getinfo(2, "S").source:sub(2)
end

local function get_parent_dir(path)
  return vim.fn.fnamemodify(path, ":h")
end

local function get_version_script_path()
  return get_parent_dir(get_parent_dir(get_parent_dir(script_path()))) .. "/scripts/version_from_tag.py"
end

local M = {}

function M.check()
  vim.health.start "python-import"

  if vim.fn.has "nvim-0.10.0" == 1 then
    vim.health.ok "Using Neovim >= 0.10.0"
  else
    vim.health.error "Neovim >= 0.10.0 is required"
  end

  for _, cmd in ipairs { "rg", "fd" } do
    if vim.fn.executable(cmd) == 1 then
      vim.health.ok(("`%s` is installed"):format(cmd))
    else
      vim.health.error(("`%s` is not installed"):format(cmd))
    end
  end

  local cmd = "python-import"
  if vim.fn.executable(cmd) == 1 then
    vim.health.ok(("`%s` is installed"):format(cmd))
    local response = vim.system({ "python-import", "--version" }, { text = true }):wait()
    if response.code == 0 then
      local python_import_cli_version = response.stdout:gsub("\n$", "")
      python_import_cli_version = python_import_cli_version:gsub("^python%-import v", "")

      local response2 = vim.system({ "python3", get_version_script_path() }, { text = true }):wait()
      if response2.code == 0 then
        local python_import_nvim_version = response2.stdout:gsub("\n$", "")
        if python_import_cli_version == python_import_nvim_version then
          vim.health.ok(
            ("python-import cli and nvim plugin version matching. Built correctly with %s."):format(
              python_import_nvim_version
            )
          )
        else
          vim.health.error(
            ("python-import cli (%s) and nvim plugin version (%s) mismatch."):format(
              python_import_cli_version,
              python_import_nvim_version
            )
          )
        end
      else
        vim.health.error "Failed to get version from tag"
      end
    else
      vim.health.error(("`%s` is not working"):format(cmd))
    end
  else
    vim.health.error(("`%s` is not installed"):format(cmd))
  end
end

---@return boolean
function M.is_python_cli_installed()
  for _, cmd in ipairs { "rg", "fd", "python-import" } do
    if vim.fn.executable(cmd) ~= 1 then
      return false
    end
  end

  return true
end

return M
