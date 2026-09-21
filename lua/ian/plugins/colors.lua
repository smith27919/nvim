-- The workstation uses colors/amber.lua (set in lua/ian/set.lua).
-- Every other machine uses catppuccin.
local workstation = vim.uv.os_gethostname() == "dell-fedora-workstation"

return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    cond = not workstation,
    -- load before every other plugin, so they all see the colors
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd.colorscheme("catppuccin")
      vim.api.nvim_set_hl(0, "ColorColumn", { bg = "#45475A" })  -- marker color
      vim.api.nvim_set_hl(0, "CursorLine", { bg = "#282838" })   -- current line color
    end,
  },
}
