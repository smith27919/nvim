-- `...` is the name this module was loaded as: the username link, or "core".
local ns = ...

require(ns .. ".remap")
require(ns .. ".set")
require(ns .. ".lazy_init")
require(ns .. ".deps")
require(ns .. ".update")

-- Machine-local settings (colors and the like). Git ignores lua/overrides/.
if vim.uv.fs_stat(vim.fn.stdpath("config") .. "/lua/overrides/init.lua") then
  require("overrides")
end
