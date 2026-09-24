-- Language servers. Mason installs each one that has a build for this
-- system. Some servers have builds only for Linux, macOS, and Windows, so
-- on the BSDs they come from the system packages instead (see
-- scripts/install-deps.sh). Any server in this list whose command is on
-- the PATH is enabled, wherever it came from.
local servers = {
  -- systems
  "clangd",          -- c, c++, objective-c
  "rust_analyzer",   -- rust
  "gopls",           -- go
  "zls",             -- zig
  "serve_d",         -- d
  "nim_langserver",  -- nim
  "crystalline",     -- crystal
  "v_analyzer",      -- v
  "ada_ls",          -- ada
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
}

-- Mason reports PLATFORM_UNSUPPORTED when a package has no build for
-- this system. Those are skipped, so they do not fail on every start.
local function supported(pkg)
  local ok, result = pcall(require("mason-core.installer.compiler").parse, pkg.spec, {})
  return not ok or not result:is_failure()
end

-- Mason's name map is out of date for these, so name the package here.
local package_names = {
  ada_ls = "ada-language-server",
}

-- Formatters for conform.nvim (see format.lua). These are Mason package names.
local formatters = { "prettier", "black", "shfmt" }

-- The languages you chose in the :Deps picker (see languages.lua).
local languages = require("core.languages")

local function install_missing()
  -- Headless runs (`nvim --headless "+Lazy! sync"`) exit before an install
  -- can finish, so do not start one.
  if #vim.api.nvim_list_uis() == 0 then
    return
  end
  -- Before the first choice, install nothing. The picker calls this
  -- again when you confirm, so an unwanted server never starts to build.
  local choices = languages.load()
  if not choices then
    return
  end
  local skip = languages.skipped(choices)
  local registry = require("mason-registry")
  local to_package = require("mason-lspconfig").get_mappings().lspconfig_to_package
  local names = {}
  for _, name in ipairs(formatters) do
    if not skip[name] then
      table.insert(names, name)
    end
  end
  for _, server in ipairs(servers) do
    if not skip[server] then
      table.insert(names, package_names[server] or to_package[server])
    end
  end
  for _, name in ipairs(names) do
    local ok, pkg = pcall(registry.get_package, name)
    if ok and not pkg:is_installed() and not pkg:is_installing() and supported(pkg) then
      pkg:install()
    end
  end
end

-- Servers from the system packages. Mason's bin folder is on the PATH too,
-- so this also covers servers that Mason has installed.
local function enable_from_path()
  for _, server in ipairs(servers) do
    local cmd = (vim.lsp.config[server] or {}).cmd
    if type(cmd) == "table" and vim.fn.executable(cmd[1]) == 1 then
      vim.lsp.enable(server)
    end
  end
end

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
    config = function()
      require("mason-lspconfig").setup()
      -- The registry is downloaded on the first start, so wait for it.
      require("mason-registry").refresh(vim.schedule_wrap(install_missing))
      enable_from_path()
      -- The :Deps picker sends this when you confirm your languages.
      vim.api.nvim_create_autocmd("User", {
        pattern = "DepsChoices",
        callback = function()
          require("mason-registry").refresh(vim.schedule_wrap(install_missing))
        end,
      })
    end,
  },
}
