vim.g.mapleader = " "
vim.keymap.set("n", "<leader>fd", vim.cmd.Ex)

vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")

-- Windows has no execute bit.
if vim.fn.has("win32") == 0 then
  vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true })
end
