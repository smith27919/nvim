-- telescope is not on the runtimepath until a key fires, so the
-- require has to happen inside the callback, not at file scope.
local function pick(name, opts)
  return function()
    require("telescope.builtin")[name](opts)
  end
end

return {
  {
    "nvim-telescope/telescope.nvim",
    tag = "v0.2.2",
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd = "Telescope",
    keys = {
      {
        "<leader>ff",
        pick("find_files", { hidden = true }),
        desc = "Telescope find files",
      },
      {
        "<leader>fc",
        pick("commands"),
        desc = "Telescope available plugin/user commands",
      },
      { "<leader>fs", pick("live_grep"), desc = "Telescope live grep" },
      { "<leader>fv", pick("vim_options"), desc = "Telescope vim options" },
      { "<leader>fkm", pick("keymaps"), desc = "Telescope keymaps" },
      { "<leader>fh", pick("command_history"), desc = "Telescope command history" },
      { "<leader>fg", pick("git_files"), desc = "Telescope git files" },
    },
  },
}
