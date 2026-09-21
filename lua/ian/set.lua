-- line numbers
vim.opt.number = true                  -- turn on line numbers
vim.opt.relativenumber = false         -- absolute, not relative
vim.opt.statuscolumn = table.concat({  -- custom number column

        "%s",
        "%{% v:relnum == 0 ",
        "? '%#CursorLineNr#' .. printf('%2d', v:lnum) .. '%*' ",
        ": printf('%3d', v:lnum) %}",
        " ",
})                              

-- indentation
vim.opt.tabstop = 4         -- tab width
vim.opt.softtabstop = 4     -- Tab key width
vim.opt.shiftwidth = 4      -- indent width
vim.opt.expandtab = true    -- spaces, not tabs

-- appearance
vim.opt.cursorline = true       -- highlight current line
vim.opt.cursorlineopt = "both"  -- number and row
vim.opt.guicursor = "n-v-c-sm:ver25,i-ci-ve:ver25,r-cr-o:ver25"  -- bar cursor
vim.opt.wrap = false            -- no line wrapping
vim.opt.colorcolumn = "90"      -- width marker
vim.opt.signcolumn = "yes"      -- always show gutter
vim.opt.scrolloff = 8           -- context lines around cursor

-- colors: the workstation uses amber, other machines use catppuccin
-- (see lua/ian/plugins/colors.lua)
if vim.uv.os_gethostname() == "dell-fedora-workstation" then
    vim.cmd.colorscheme("amber")
end

-- behavior
vim.opt.undofile = true     -- persistent undo
vim.opt.hlsearch = true     -- highlight search matches
vim.opt.updatetime = 100    -- idle delay in ms
