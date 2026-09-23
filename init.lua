-- vim.lsp.config and terminal jobs need Neovim 0.11. Stop with one clear
-- message, instead of many errors from the plugins.
if vim.fn.has("nvim-0.11") == 0 then
  vim.api.nvim_echo({ { "This config needs Neovim 0.11 or newer.", "ErrorMsg" } }, true, {})
  return
end

-- The config lives in lua/core/, which git tracks. Each user gets a link
-- lua/<username> -> core, so the module is named after the person who
-- installed it. Git ignores the link. Lua reads "." in a module name as a
-- folder, so "ian.smith" becomes "ian_smith".
local user = (vim.env.USER or vim.uv.os_get_passwd().username or "user"):gsub("[^%w_]", "_")
local link = vim.fn.stdpath("config") .. "/lua/" .. user

if user ~= "core" and user ~= "overrides" and not vim.uv.fs_lstat(link) then
  vim.uv.fs_symlink("core", link)
end

-- Use the link only when it points to core. If something else has the
-- name (a leftover folder from an old layout, for example), load core
-- directly, so the config always starts.
if vim.uv.fs_readlink(link) == "core" then
  require(user)
else
  require("core")
end
