return {
  {
    "mason-org/mason.nvim",
    -- An empty opts table still means "call setup()". Without opts or
    -- config, lazy installs the plugin but never sets it up.
    opts = {},
  },
  {
    "mason-org/mason-lspconfig.nvim",
    -- lazy sequences dependencies, so mason and lspconfig load first
    dependencies = {
      "mason-org/mason.nvim",
      "neovim/nvim-lspconfig",
    },
    opts = {
      ensure_installed = {
        "lua_ls",   -- lua
        "clangd",   -- c and c++
        "jdtls",    -- java
        "ts_ls",    -- javascript and typescript
        "pyright",  -- python
      },
    },
  },
}
