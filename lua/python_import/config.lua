local M = {}

M.opts = {}
M.default_opts = {
  extend_lookup_table = {
    ---@type string[]
    import = {
      -- "pickle",
    },

    ---@type table<string, string|vim.NIL>
    import_as = {
      -- np = "numpy",
      -- pd = "pandas",
    },

    ---@type table<string, string|vim.NIL>
    import_from = {
      -- tqdm = "tqdm.auto",
      -- nn = "torch",
    },

    ---@type table<string, string[]|vim.NIL>
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
}

return M
