-- Taken from wookayin/dotfiles
--- Additional treesitter utilities used throughout neovim config
-- Note: nvim-treesitter.ts_utils are deprecated; should not depend on it.
-- Note: Use the new vim.treesitter APIs (v0.9.0+) as much as possible.

local M = {}

--- Get the treesitter node (the most ancestor) that contains
--- the current cursor location in the range.
---
--- Differences to `vim.treesitter.get_node()` or `nvim-treesitter.ts_utils.get_node_at_cursor()`:
---
--- 1. This is aware of the "insert mode" to have a better offset on cursor_range. For example:
---
---    1234567 8
---    "foobar|"
---    ^^     ^^
---    ││     ││
---    ││     │└─ string
---    ││     └─ cursor (insert mode)
---    │└─ string_content
---    └─ string
---
---    In the insert mode, the cursor location (1-indexed) will read col = 8, so the
---    original get_node_at_cursor() implementation will return the `string` node at col = 8.
---    But in the insert mode, we would want to get the `string_content` node at col = 7.
---
--- 2. When parser is not available or mis-configured, it will raise errors.
---
---    Use vim.F.npcall() to make error-safe!
---
---
---@param winnr? integer window number, 0 (the current window) by default
---@param ignore_injections? boolean defaults true
---@return TSNode|nil
function M.get_node_at_cursor(winnr, ignore_injections)
  winnr = winnr or 0
  local cursor = vim.api.nvim_win_get_cursor(winnr) -- line: 1-indexed, col: 0-indexed
  local insert_offset = ((winnr == 0 or winnr == vim.api.nvim_get_current_win()) and vim.fn.mode() == "i") and 1 or 0

  -- Treesitter: row, col are both 0-indexed
  local cursor_pos = { cursor[1] - 1, cursor[2] - insert_offset }
  assert(vim.treesitter.get_node, "nvim < 0.9 is unsupported.")

  return vim.treesitter.get_node { pos = cursor_pos, ignore_injections = ignore_injections }
end

return M
