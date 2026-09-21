-- harpoon is not on the runtimepath until a key fires, so every
-- require has to happen inside the callback, not at file scope.
local function nav(n)
  return function()
    require("harpoon.ui").nav_file(n)
  end
end

return {
  {
    "ThePrimeagen/harpoon",
    keys = {
      {
        "<leader>a",
        function() require("harpoon.mark").add_file() end,
        desc = "Harpoon add file",
      },
      {
        "<C-e>",
        function() require("harpoon.ui").toggle_quick_menu() end,
        desc = "Harpoon menu",
      },
      { "<C-h>", nav(1), desc = "Harpoon file 1" },
      { "<C-j>", nav(2), desc = "Harpoon file 2" },
      { "<C-k>", nav(3), desc = "Harpoon file 3" },
      { "<C-l>", nav(4), desc = "Harpoon file 4" },
    },
  },
  {
    "mbbill/undotree",
    cmd = "UndotreeToggle",
    keys = {
      { "<leader>u", vim.cmd.UndotreeToggle, desc = "Undotree toggle" },
    },
  },
  {
    "tpope/vim-fugitive",
    cmd = { "Git", "G" },
    keys = {
      { "<leader>gs", vim.cmd.Git, desc = "Fugitive status" },
    },
  },
}
