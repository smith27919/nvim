-- Update notice and :ConfigUpdate.
-- At startup, fetch the repo in the background. If it has new commits,
-- show one line. :ConfigUpdate pulls them and updates the plugins.
local config = vim.fn.stdpath("config")

-- Never ask for a password or passphrase from the background: fail quietly.
local git_env = {
  GIT_TERMINAL_PROMPT = "0",
  GIT_SSH_COMMAND = "ssh -o BatchMode=yes",
}

local function git(args, on_exit)
  local cmd = { "git", "-C", config }
  vim.list_extend(cmd, args)
  return vim.system(cmd, { text = true, env = git_env }, on_exit and vim.schedule_wrap(on_exit))
end

local function notice()
  git({ "fetch", "--quiet" }, function(fetch)
    if fetch.code ~= 0 then
      return
    end
    git({ "rev-list", "--count", "HEAD..@{upstream}" }, function(count)
      local n = tonumber(vim.trim(count.stdout or ""))
      if count.code == 0 and n and n > 0 then
        local commits = n == 1 and "1 new commit" or (n .. " new commits")
        vim.notify("Config update available (" .. commits .. "): run :ConfigUpdate")
      end
    end)
  end)
end

-- The lockfile changes on its own (plugin updates, your own plugins in
-- lua/overrides/plugins/). It is safe to reset. Any other changed file
-- stops the update, so no work is lost.
local function local_changes(status)
  local others = {}
  for line in status:gmatch("[^\n]+") do
    local path = line:sub(4)
    if path ~= "lazy-lock.json" then
      table.insert(others, path)
    end
  end
  return others
end

local function update()
  git({ "status", "--porcelain", "--untracked-files=no" }, function(status)
    local others = local_changes(status.stdout or "")
    if #others > 0 then
      vim.notify("Update stopped. These files have local changes:\n  "
        .. table.concat(others, "\n  ")
        .. "\nCommit them, or move your changes to lua/overrides/.", vim.log.levels.WARN)
      return
    end
    git({ "checkout", "--", "lazy-lock.json" }, function()
      vim.notify("Pulling the config...")
      git({ "pull", "--ff-only" }, function(pull)
        if pull.code ~= 0 then
          vim.notify("git pull failed:\n" .. (pull.stderr or ""), vim.log.levels.ERROR)
          return
        end
        -- A new Neovim loads the new config, so the plugins match the new lockfile.
        vim.notify("Updating the plugins...")
        vim.system({ vim.v.progpath, "--headless", "+Lazy! restore", "+qa" }, {}, vim.schedule_wrap(function()
          vim.notify("Config updated. Restart Neovim (or run :restart) to load it.")
        end))
      end)
    end)
  end)
end

vim.api.nvim_create_user_command("ConfigUpdate", update, { desc = "Pull the config and update the plugins" })

vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    if #vim.api.nvim_list_uis() > 0 then
      notice()
    end
  end,
})
