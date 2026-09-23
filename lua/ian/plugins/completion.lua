-- Completion starts on. <leader>tc turns it off and on, so
-- you can type everything by hand while you learn.
vim.g.completion_enabled = true

local function toggle()
  vim.g.completion_enabled = not vim.g.completion_enabled
  local state = vim.g.completion_enabled and "on" or "off"
  vim.notify("Completion " .. state)
end

return {
  {
    "saghen/blink.cmp",
    -- 1.* gets a prebuilt release, so no Rust compile is necessary
    version = "1.*",
    event = "InsertEnter",
    dependencies = { "rafamadriz/friendly-snippets" },
    keys = {
      { "<leader>tc", toggle, desc = "Toggle completion" },
    },
    opts = {
      enabled = function()
        return vim.g.completion_enabled
      end,
      -- super-tab: Tab accepts the item, as in VS Code
      keymap = { preset = "super-tab" },
      sources = {
        default = { "lsp", "path", "snippets", "buffer" },
      },
    },
  },
}
