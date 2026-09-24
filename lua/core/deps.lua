-- Runs scripts/install-deps.sh once after each git pull of this config.
-- The script stays in the repo. A marker file outside the repo holds the
-- commit that was last checked, so a new commit or pull means a new check.
-- :Deps runs the script at any time.
local M = {}

local config = vim.fn.stdpath("config")
local script = config .. "/scripts/install-deps.sh"
local marker = vim.fn.stdpath("state") .. "/deps-checked"

-- The script exits with this code when you ask it to restart Neovim.
local RESTART = 10

local function read_marker()
  local f = io.open(marker, "r")
  if not f then
    return nil
  end
  local commit = f:read("*l")
  f:close()
  return commit
end

local function write_marker(commit)
  if not commit then
    return
  end
  vim.fn.mkdir(vim.fn.fnamemodify(marker, ":h"), "p")
  local f = io.open(marker, "w")
  if f then
    f:write(commit, "\n")
    f:close()
  end
end

-- The installer's window, while its script runs.
local installer_win

local function running()
  return installer_win ~= nil and vim.api.nvim_win_is_valid(installer_win)
end

-- Go back to the installer and type into it.
local function focus()
  if running() then
    vim.api.nvim_set_current_win(installer_win)
    vim.cmd("startinsert")
  end
end

-- Lazy shows its window at the first start. Close it, so the installer
-- is the only popup.
local function close_lazy()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "lazy" then
      pcall(vim.api.nvim_win_close, win, true)
    end
  end
end

local function open_float(buf)
  local width = math.min(100, vim.o.columns - 4)
  local height = math.min(24, vim.o.lines - 6)
  return vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2) - 1,
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "rounded",
    title = " Dependency installer ",
    title_pos = "center",
    footer = " Type your answer, then push Enter. Ctrl+c stops. ",
    footer_pos = "center",
    -- Above other floats, such as Lazy (50).
    zindex = 200,
  })
end

-- Show the script in a float. The float keeps the focus and stays in
-- terminal mode until the script ends, so a click or another popup
-- cannot leave you unable to type.
function M.open_installer(commit)
  if running() then
    focus()
    return
  end
  close_lazy()
  local buf = vim.api.nvim_create_buf(false, true)
  local win = open_float(buf)
  installer_win = win

  local group = vim.api.nvim_create_augroup("DepsInstaller", { clear = true })
  -- A click or Ctrl+\ Ctrl+n leaves terminal mode. Go straight back.
  vim.api.nvim_create_autocmd("ModeChanged", {
    group = group,
    pattern = "t:*",
    callback = function()
      if vim.api.nvim_get_current_win() == win then
        vim.schedule(focus)
      end
    end,
  })
  -- Lazy can open its window after the installer. Close it too.
  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = "lazy",
    callback = function()
      vim.schedule(close_lazy)
    end,
  })
  -- Another window took the focus. Take it back.
  vim.api.nvim_create_autocmd("WinEnter", {
    group = group,
    callback = function()
      if vim.api.nvim_get_current_win() ~= win then
        vim.schedule(focus)
      end
    end,
  })

  vim.fn.jobstart({ script }, {
    term = true,
    on_exit = function(_, code)
      vim.schedule(function()
        installer_win = nil
        vim.api.nvim_del_augroup_by_id(group)
        if vim.api.nvim_buf_is_valid(buf) then
          vim.api.nvim_buf_delete(buf, { force = true })
        end
        -- A failed or stopped install is not marked, so the check runs
        -- again on the next start.
        if code ~= 0 and code ~= RESTART then
          vim.notify("The dependency installer did not finish. It runs again at the next start.",
            vim.log.levels.WARN)
          return
        end
        -- Mark before the restart, so the new Neovim does not ask again.
        write_marker(commit)
        if code == RESTART and not pcall(vim.cmd, "restart") then
          vim.notify("Save your files, then run :restart.", vim.log.levels.WARN)
        end
      end)
    end,
  })
  vim.cmd("startinsert")
end

-- Check once for this commit. Open the installer only if something is missing.
function M.check()
  if vim.fn.executable(script) == 0 then
    return
  end
  -- Async, so a check never slows startup.
  vim.system({ "git", "-C", config, "rev-parse", "HEAD" }, { text = true }, function(head)
    if head.code ~= 0 then
      return
    end
    local commit = vim.trim(head.stdout)
    if read_marker() == commit then
      return
    end
    vim.system({ script, "--check" }, {}, function(check)
      vim.schedule(function()
        if check.code == 0 then
          write_marker(commit)
        else
          M.open_installer(commit)
        end
      end)
    end)
  end)
end

vim.api.nvim_create_user_command("Deps", function()
  local head = vim.system({ "git", "-C", config, "rev-parse", "HEAD" }, { text = true }):wait()
  M.open_installer(head.code == 0 and vim.trim(head.stdout) or nil)
end, { desc = "Check and install system packages" })

vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    -- Skip headless runs such as `nvim --headless "+Lazy! sync"`.
    if #vim.api.nvim_list_uis() > 0 then
      M.check()
    end
  end,
})

return M
