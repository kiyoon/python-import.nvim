# python-import.nvim

A simple tool that auto-inserts import statements.

NOTE: This is work-in-progress and not yet ready for public. There isn't much customisation options and the behaviour can change rapidly.

## Requirements

- Neovim >= 0.10
- pipx
- ripgrep (`brew install ripgrep` or `cargo install ripgrep`)
- fd (`brew install fd`, `cargo install fd-find` or `npm install -g fd-find`)

## Installation

Install with lazy.nvim:

```lua
  {
    "kiyoon/python-import.nvim",
    keys = {
      {
        "<M-CR>",
        function()
          require("python_import.api").add_import_current_word_and_notify()
        end,
        mode = { "i", "n" },
        silent = true,
        desc = "Add python import",
        ft = "python",
      },
      {
        "<M-CR>",
        function()
          require("python_import.api").add_import_current_selection_and_notify()
        end,
        mode = "x",
        silent = true,
        desc = "Add python import",
        ft = "python",
      },
      {
        "<space>i",
        function()
          require("python_import.api").add_import_current_word_and_move_cursor()
        end,
        mode = { "i", "n" },
        silent = true,
        desc = "Add python import and move cursor",
        ft = "python",
      },
      {
        "<space>i",
        function()
          require("python_import.api").add_import_current_selection_and_move_cursor()
        end,
        mode = "x",
        silent = true,
        desc = "Add python import and move cursor",
        ft = "python",
      },
      {
        "<space>tr",
        function()
          require("python_import.api").add_rich_traceback()
        end,
        silent = true,
        desc = "Add rich traceback",
        ft = "python",
      },
    },
    config = function()
      require("python_import").setup {}
    end,
  },
```

## Health check


