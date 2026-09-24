-- The toolchain groups that you can choose in the :Deps picker, and the
-- servers and formatters that each group makes possible. The group ids
-- match scripts/install-deps.sh.
--
-- An unchecked group gets no system packages, and Mason skips its
-- servers. Your choices are saved per machine, outside the repo.
--
-- Load this module as "core.languages" (lazy runs plugin files without
-- a module name, so they cannot use the username link).
local M = {}

local file = vim.fn.stdpath("state") .. "/deps-choices.json"

-- `servers` are lspconfig names, `formatters` are Mason package names.
-- A server that is in two groups needs both.
M.groups = {
  {
    id = "node",
    label = "Node.js",
    languages = "TypeScript, HTML, CSS, Python, Bash, JSON, YAML, Vue, Docker, ...",
    servers = {
      "ts_ls", "html", "cssls", "tailwindcss", "emmet_language_server", "eslint",
      "vue_ls", "svelte", "angularls", "astro", "graphql", "jsonls", "yamlls",
      "dockerls", "docker_compose_language_service", "ansiblels", "bashls", "awk_ls",
      "pyright", "intelephense", "perlnavigator", "elmls", "sqlls", "prismals",
      "solidity_ls_nomicfoundation",
    },
    formatters = { "prettier" },
  },
  {
    id = "python",
    label = "Python",
    languages = "Python formatting, Fortran, Tcl",
    servers = { "fortls", "tclsp" },
    formatters = { "black" },
  },
  { id = "go", label = "Go", languages = "Go", servers = { "gopls" } },
  {
    id = "java",
    label = "Java",
    languages = "Java, Kotlin, Groovy",
    servers = { "jdtls", "kotlin_language_server", "groovyls" },
  },
  { id = "dotnet", label = ".NET", languages = "C#, F#", servers = { "csharp_ls", "fsautocomplete" } },
  { id = "ruby", label = "Ruby", languages = "Ruby", servers = { "ruby_lsp" } },
  { id = "rust", label = "Rust", languages = "Assembly (asm_lsp builds with cargo)", servers = { "asm_lsp" } },
  { id = "beam", label = "Erlang, Elixir", languages = "Erlang, Elixir", servers = { "elp", "elixirls" } },
  { id = "r", label = "R", languages = "R (its server builds from source)", servers = { "r_language_server" } },
  { id = "julia", label = "Julia", languages = "Julia", servers = { "julials" } },
  { id = "perl", label = "Perl", languages = "Perl", servers = { "perlnavigator" } },
}

-- The saved choices, { [id] = true or false }, or nil before the first choice.
function M.load()
  local f = io.open(file, "r")
  if not f then
    return nil
  end
  local ok, choices = pcall(vim.json.decode, f:read("*a"))
  f:close()
  return ok and type(choices) == "table" and choices or nil
end

function M.save(choices)
  vim.fn.mkdir(vim.fn.fnamemodify(file, ":h"), "p")
  local f = io.open(file, "w")
  if f then
    f:write(vim.json.encode(choices), "\n")
    f:close()
  end
end

-- True when the config has a group that you have not chosen yet.
function M.has_new(choices)
  for _, group in ipairs(M.groups) do
    if choices[group.id] == nil then
      return true
    end
  end
  return false
end

-- The ids of the checked groups.
function M.checked(choices)
  local ids = {}
  for _, group in ipairs(M.groups) do
    if choices[group.id] then
      table.insert(ids, group.id)
    end
  end
  return ids
end

-- The servers and formatters of the unchecked groups, as a set.
function M.skipped(choices)
  local skip = {}
  for _, group in ipairs(M.groups) do
    if not choices[group.id] then
      for _, name in ipairs(group.servers or {}) do
        skip[name] = true
      end
      for _, name in ipairs(group.formatters or {}) do
        skip[name] = true
      end
    end
  end
  return skip
end

return M
