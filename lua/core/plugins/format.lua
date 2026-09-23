-- Format on save starts off, so you learn the layout yourself.
-- <leader>tf turns it on and off. gq formats the selected lines at any time.
vim.g.format_on_save = false

local function toggle()
  vim.g.format_on_save = not vim.g.format_on_save
  local state = vim.g.format_on_save and "on" or "off"
  vim.notify("Format on save " .. state)
end

return {
  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    cmd = "ConformInfo",
    keys = {
      { "<leader>tf", toggle, desc = "Toggle format on save" },
    },
    init = function()
      -- gq uses conform. Plain gq behavior is the fallback.
      vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
    end,
    opts = {
      -- Formatters that Mason installs (see lsp.lua). Other languages use
      -- the language server's formatter, when it has one.
      formatters_by_ft = {
        python = { "black" },
        sh = { "shfmt" },
        bash = { "shfmt" },
        javascript = { "prettier" },
        javascriptreact = { "prettier" },
        typescript = { "prettier" },
        typescriptreact = { "prettier" },
        vue = { "prettier" },
        css = { "prettier" },
        scss = { "prettier" },
        less = { "prettier" },
        html = { "prettier" },
        json = { "prettier" },
        jsonc = { "prettier" },
        yaml = { "prettier" },
        markdown = { "prettier" },
        graphql = { "prettier" },
      },
      default_format_opts = { lsp_format = "fallback" },
      format_on_save = function()
        if vim.g.format_on_save then
          return { timeout_ms = 1000 }
        end
      end,
    },
  },
}
