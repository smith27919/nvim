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
          -- systems
          "clangd",          -- c, c++, objective-c
          "rust_analyzer",   -- rust
          "gopls",           -- go
          "zls",             -- zig
          "serve_d",         -- d
          "nim_langserver",  -- nim
          "crystalline",     -- crystal
          "v_analyzer",      -- v
          "ada_language_server", -- ada
          "asm_lsp",         -- assembly (needs cargo)
          -- jvm and .net
          "jdtls",           -- java
          "kotlin_language_server", -- kotlin
          "groovyls",        -- groovy (needs javac to build)
          "clojure_lsp",     -- clojure
          "csharp_ls",       -- c# (needs dotnet)
          "fsautocomplete",  -- f# (needs dotnet)
          -- scripting
          "pyright",         -- python
          "ruby_lsp",        -- ruby (needs ruby)
          "intelephense",    -- php
          "perlnavigator",   -- perl
          "lua_ls",          -- lua
          "bashls",          -- bash and sh
          "awk_ls",          -- awk
          "tclsp",           -- tcl
          -- functional
          "elixirls",        -- elixir (needs elixir)
          "elp",             -- erlang (needs erlang)
          "elmls",           -- elm
          "millet",          -- standard ml
          -- science and data
          "r_language_server", -- r (needs r)
          "julials",         -- julia (needs julia)
          "fortls",          -- fortran
          "sqlls",           -- sql
          "prismals",        -- prisma schema
          -- other production languages
          "cobol_ls",        -- cobol
          "solidity_ls_nomicfoundation", -- solidity
          "vhdl_ls",         -- vhdl
          "verible",         -- verilog and systemverilog
          -- frontend
          "ts_ls",           -- javascript and typescript
          "html",            -- html
          "cssls",           -- css, scss, less
          "tailwindcss",     -- tailwind classes
          "emmet_language_server", -- html shorthand
          "eslint",          -- javascript linting
          "vue_ls",          -- vue
          "svelte",          -- svelte
          "angularls",       -- angular
          "astro",           -- astro
          "graphql",         -- graphql
          -- config and infrastructure
          "jsonls",          -- json
          "yamlls",          -- yaml
          "taplo",           -- toml
          "lemminx",         -- xml
          "dockerls",        -- dockerfile
          "docker_compose_language_service", -- docker compose
          "terraformls",     -- terraform
          "helm_ls",         -- helm charts
          "ansiblels",       -- ansible
          "neocmake",        -- cmake (no python needed)
          -- notes
          "marksman",        -- markdown
        },
      },
    },
  }
