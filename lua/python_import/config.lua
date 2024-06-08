M = {}

M.opts = {}
M.default_opts = {
  extend_lookup_table = {
    import = {
      -- "pickle",
    },
    import_as = {
      -- np = "numpy",
      -- pd = "pandas",
    },
    import_from = {
      -- tqdm = "tqdm.auto",
      -- nn = "torch",
    },
    statement_after_imports = {
      -- logger = { "import my_custom_logger", "", "logger = my_custom_logger.get_logger()" },
    },
  },
}

return M
