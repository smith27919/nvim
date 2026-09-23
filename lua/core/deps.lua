-- Runs scripts/install-deps.sh once after each git pull of this config.
-- The script stays in the repo. A marker file outside the repo holds the
-- commit that was last checked, so a new commit or pull means a new check.
-- :Deps runs the script at any time.
local M = {}

local config = vim.fn.stdpath("config")
local script = config .. "/scripts/install-deps.sh"
local marker = vim.fn.stdpath("state") .. "/deps-checked"

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

-- Show the script in a split so it can ask.
function M.open_installer(commit)
  vim.cmd("botright 20split")
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(0, buf)
  vim.fn.jobstart({ script }, {
    term = true,
    on_exit = function(_, code)
      -- A failed install (wrong password, dnf error) is not marked,
      -- so the check runs again on the next start.
      if code == 0 then
        write_marker(commit)
        vim.schedule(function()
          if vim.api.nvim_buf_is_valid(buf) then
            vim.api.nvim_buf_delete(buf, { force = true })
          end
        end)
      end
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
