-- Push <leader> (Space) and wait: a popup lists the keys you can push next.
return {
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      -- Icons need a Nerd Font. Without one they show as empty boxes.
      icons = { mappings = false },
      spec = {
        { "<leader>f", group = "find" },
        { "<leader>fk", group = "keymaps" },
        { "<leader>g", group = "git" },
        { "<leader>t", group = "toggle" },
      },
    },
  },
}
