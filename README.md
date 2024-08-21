# 🐍 python-import.nvim

|  |  |
|--|--|
|[![Ruff](https://img.shields.io/badge/Ruff-3670A0?style=for-the-badge&logo=python&logoColor=ffdd54)](https://github.com/astral-sh/ruff) |[![Actions status](https://github.com/kiyoon/python-import.nvim/workflows/Style%20checking/badge.svg)](https://github.com/kiyoon/python-import.nvim/actions)|
| [![Ruff](https://img.shields.io/badge/Ruff-3670A0?style=for-the-badge&logo=python&logoColor=ffdd54)](https://github.com/astral-sh/ruff) | [![Actions status](https://github.com/kiyoon/python-import.nvim/workflows/Linting/badge.svg)](https://github.com/kiyoon/python-import.nvim/actions) |
| [![pytest](https://img.shields.io/badge/pytest-3670A0?style=for-the-badge&logo=python&logoColor=ffdd54)](https://github.com/pytest-dev/pytest) [![doctest](https://img.shields.io/badge/doctest-3670A0?style=for-the-badge&logo=python&logoColor=ffdd54)](https://docs.python.org/3/library/doctest.html) | [![Actions status](https://github.com/kiyoon/python-import.nvim/workflows/Tests/badge.svg)](https://github.com/kiyoon/python-import.nvim/actions) |
| [![uv](https://img.shields.io/badge/uv-3670A0?style=for-the-badge&logo=python&logoColor=ffdd54)](https://github.com/astral-sh/uv) | [![Actions status](https://github.com/kiyoon/python-import.nvim/workflows/Check%20pip%20compile%20sync/badge.svg)](https://github.com/kiyoon/python-import.nvim/actions) |
|[![Ruff](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/astral-sh/ruff/main/assets/badge/v2.json)](https://github.com/astral-sh/ruff) [![StyLua](https://img.shields.io/badge/lua-%232C2D72.svg?style=for-the-badge&logo=lua&logoColor=white)](https://github.com/JohnnyMorganz/StyLua) | [![Actions status](https://github.com/kiyoon/python-import.nvim/workflows/Style%20checking/badge.svg)](https://github.com/kiyoon/python-import.nvim/actions) |

A simple tool that auto-inserts import statements.

https://github.com/kiyoon/python-import.nvim/assets/12980409/8a8f580f-16de-460c-af32-23fab7d2a35e

It matches with:

1. [Pre-defined lookup tables](https://github.com/kiyoon/python-import.nvim/blob/master/lua/python_import/lookup_table.lua)
2. Existing imports in the project (implemented in Python: `python-import` cli)
    - It finds the imports in the project and shows a list of them to choose from.
3. pyright/basedpyright LSP completion
4. Just `import <word>` :P

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

Most will use the current word to find the import statement, but the treesitter node can be used to find the import statement more accurately. (e.g. `class SomeDataset(torch.utils.data.DataLoader)` -> `import torch.utils.data`)

> [!WARNING]
> This work-in-progress plugin is not yet ready for the public.
> There aren't many customisation options (e.g. how to locate the import place)
> and the behaviour and build/configuration instructions change rapidly.
> If you don't want breaking changes, please fix the version of this plugin.

## 🛠️ Installation

### Requirements

- 💻 Neovim >= 0.10
- pipx or uv (or any other way to install `python-import` cli in PATH)
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
      ---@type fun(winnr: integer, word: string, ts_node: TSNode?): string[]?
      custom_function = function(winnr, word, ts_node)
        -- if vim.endswith(word, "_DIR") then
        --   return { "from my_module import " .. word }
        -- end
      end,
    },
  },
  "rcarriga/nvim-notify",   -- optional
```

### Faster building with `uv`

`pipx` is easy to configure, but `uv` is much faster. Make sure to install uv >= 0.2 and change the build script as follows:

With lazy.nvim:

```lua
  {
    "kiyoon/python-import.nvim",
    build = "bash scripts/build_with_uv.sh ~/.virtualenvs/python-import",
    -- Other configurations ...
  },
```

This simply creates a virtual environment in `~/.virtualenvs/python-import` and installs the cli there with `uv pip install .`. Then it sym-links the binary to `~/.local/bin/python-import`.

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
- ERROR python-import cli (0.1.0+41.g9513418.dirty) and nvim plugin version (0.1.0+42.g9f74e1d.dirty) mismatch.
```

## TODO
- [ ] Add more tests
- [ ] Command to add imports in TYPE_CHECKING
- [ ] Command to add lazy imports in methods
- [ ] Command to add imports in jupytext cell
- [ ] Search in ipynb files
- [ ] VSCode-neovim integration (use `vim.ui.select` for vscode UI support. However, this complicates stuff because it runs async)
    - Currently, if you open the vscode-neovim output terminal, it is quite usable. The notification works as well. LSP doesn't work yet.
