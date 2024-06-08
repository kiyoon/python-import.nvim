# 🐍 python-import.nvim

A simple tool that auto-inserts import statements.

https://github.com/kiyoon/python-import.nvim/assets/12980409/8a8f580f-16de-460c-af32-23fab7d2a35e

The function receives the current word and treesitter node under the cursor.  
Most will use the current word to find the import statement, but the treesitter node can be used to find the import statement more accurately. (e.g. `torch.utils.data.DataLoader` -> `import torch.utils.data`)

```mermaid
graph TD
    A[Current word] --> B[Lookup table]
    B --> C<Match?>
    C -->|Yes| D[Insert import statement]
    C -->|No| E[Find imports in project]
    E --> F<Match found?>
    F -->|Yes| G[Select one and insert import statement]
    F -->|No| H[Insert import word]
```

1. Match lookup table with the current word
2. If there is a match, insert the import statement
3. If there is no match, rank all import statements by occurrence in the project and prompt the user to select one.
4. If no match in the project either, just `import <word>`.

It uses treesitter to find the most suitable location to insert the import statement. (e.g. after the docstring and comments, or at the last import statement)

This plugin doesn't detect duplicated imports. Use `ruff` to sort imports.

### Lookup table examples

- `Path` -> `from pathlib import Path`
- `np` -> `import numpy as np`
- `torch` -> `import torch`
- `logging` -> `import logging`
- `logger` ->  
```python
import logging

logger = logging.getLogger(__name__)
```

NOTE: This is work-in-progress and not yet ready for public. There isn't much customisation options and the behaviour can change rapidly.

## 🛠️ Installation

### Requirements

- 💻 Neovim >= 0.10
- pipx (or any other way to install `python-import` cli in PATH)
- ripgrep (`brew install ripgrep` or `cargo install ripgrep`)
- fd (`brew install fd`, `cargo install fd-find` or `npm install -g fd-find`)


### Install with lazy.nvim:

```lua
  {
    "kiyoon/python-import.nvim",
    build = "pipx install . --force",
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
        mode = "n",
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
    opts = {
      -- Example 1:
        -- Default behaviour for `tqdm` is `from tqdm.auto import tqdm`.
        -- If you want to change it to `import tqdm`, you can set `import = {"tqdm"}` and `import_from = {tqdm = nil}` here.
        -- If you want to change it to `from tqdm import tqdm`, you can set `import_from = {tqdm = "tqdm"}` here.

      -- Example 2:
        -- Default behaviour for `logger` is `import logging`, ``, `logger = logging.getLogger(__name__)`.
        -- If you want to change it to `import my_custom_logger`, ``, `logger = my_custom_logger.get_logger()`,
        -- you can set `statement_after_imports = {logger = {"import my_custom_logger", "", "logger = my_custom_logger.get_logger()"}}` here.
        extend_lookup_table = {
          ---@type string[]
          import = {
            -- "tqdm",
          },

          ---@type table<string, string>
          import_as = {
            -- These are the default values. Here for demonstration.
            -- np = "numpy",
            -- pd = "pandas",
          },

          ---@type table<string, string>
          import_from = {
            -- tqdm = nil,
            -- tqdm = "tqdm",
          },

          ---@type table<string, string[]>
          statement_after_imports = {
            -- logger = { "import my_custom_logger", "", "logger = my_custom_logger.get_logger()" },
          },
        },

        ---Return nil to indicate no match is found and continue with the default lookup
        ---Return a table to stop the lookup and use the returned table as the result
        ---Return an empty table to stop the lookup. This is useful when you want to add to wherever you need to.
        ---@type fun(bufnr: integer, word: string, ts_node: TSNode?): string[]?
        custom_function = function(bufnr, word, ts_node)
          -- if vim.endswith(word, "_DIR") then
          --   return { "from my_module import " .. word }
          -- end
        end,
      },
    },
  },
  "rcarriga/nvim-notify",   -- optional
```

###  🏋️ Health check

Run `:checkhealth python_import` and see if python-import.nvim is installed correctly.  
You need to disable lazy loading or run any commands in a python file to activate the plugin first.

```
==============================================================================
python_import: require("python_import.health").check()

python-import ~
- OK Using Neovim >= 0.10.0
- OK `rg` is installed
- OK `fd` is installed
- OK `python-import` is installed
- OK python-import v0.1.0+14.g64ef2f2
```
