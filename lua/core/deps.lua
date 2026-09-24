-- Runs scripts/install-deps.sh once after each git pull of this config.
-- The script stays in the repo. A marker file outside the repo holds the
-- commit that was last checked, so a new commit or pull means a new check.
--
-- First a picker asks which languages you want (see languages.lua). Then
-- the script installs the missing toolchains for the checked ones.
-- :Deps opens the picker at any time.
local M = {}

local languages = require("core.languages")

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

-- Lazy shows its window at the first start. Close it, so the picker or
-- the installer is the only popup.
local function close_lazy()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "lazy" then
      pcall(vim.api.nvim_win_close, win, true)
    end
  end
end

-- The open float (picker or installer), so :Deps can go back to it.
local current_win

local function open_float(buf, title, footer, height)
  local width = math.min(100, vim.o.columns - 4)
  height = math.min(height, vim.o.lines - 6)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2) - 1,
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "rounded",
    title = title,
    title_pos = "center",
    footer = footer,
    footer_pos = "center",
    -- Above other floats, such as Lazy (50).
    zindex = 200,
  })
  current_win = win
  return win
end

-- Keep the focus in win until it closes: close Lazy if it opens, and
-- take the focus back from any other window. With terminal = true, also
-- go back to terminal mode after a click or Ctrl+\ Ctrl+n.
-- Returns a function that removes the guard.
local function guard(win, terminal)
  local function focus()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_set_current_win(win)
      if terminal then
        vim.cmd("startinsert")
      end
    end
  end
  local group = vim.api.nvim_create_augroup("DepsFloat", { clear = true })
  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = "lazy",
    callback = function()
      vim.schedule(close_lazy)
    end,
  })
  vim.api.nvim_create_autocmd("WinEnter", {
    group = group,
    callback = function()
      if vim.api.nvim_get_current_win() ~= win then
        vim.schedule(focus)
      end
    end,
  })
  if terminal then
    vim.api.nvim_create_autocmd("ModeChanged", {
      group = group,
      pattern = "t:*",
      callback = function()
        if vim.api.nvim_get_current_win() == win then
          vim.schedule(focus)
        end
      end,
    })
  end
  return function()
    pcall(vim.api.nvim_del_augroup_by_id, group)
    if current_win == win then
      current_win = nil
    end
  end
end

-- Tell Mason (see plugins/lsp.lua) to install the servers you allowed.
local function choices_changed()
  vim.api.nvim_exec_autocmds("User", { pattern = "DepsChoices" })
end

-- Run the script in a terminal float for the checked groups. The float
-- keeps the focus and stays in terminal mode until the script ends.
function M.open_installer(commit, groups)
  close_lazy()
  local buf = vim.api.nvim_create_buf(false, true)
  local win = open_float(buf, " Dependency installer ",
    " Type your answer, then push Enter. Ctrl+c stops. ", 24)
  local unguard = guard(win, true)

  vim.fn.jobstart({ script, "--groups", table.concat(groups, " ") }, {
    term = true,
    on_exit = function(_, code)
      vim.schedule(function()
        unguard()
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
        if code == RESTART then
          if not pcall(vim.cmd, "restart") then
            vim.notify("Save your files, then run :restart.", vim.log.levels.WARN)
          end
        else
          choices_changed()
        end
      end)
    end,
  })
  vim.cmd("startinsert")
end

-- Status text and highlight for each result of `install-deps.sh --list`.
local status_text = {
  ok = { "installed", "DiagnosticOk" },
  missing = { "not installed", "DiagnosticWarn" },
  na = { "no package for this system", "Comment" },
}

local ns = vim.api.nvim_create_namespace("deps_picker")

-- The checkbox list. statuses is { [id] = "ok" | "missing" | "na" };
-- it is empty when the script cannot tell (no supported package manager).
local function open_picker(commit, statuses)
  close_lazy()
  local saved = languages.load() or {}
  local rows = {}
  for _, group in ipairs(languages.groups) do
    local status = statuses[group.id]
    local checked = saved[group.id]
    if checked == nil then
      -- A new group starts checked, unless it cannot be installed.
      checked = status ~= "na"
    end
    table.insert(rows, { group = group, status = status, checked = checked and status ~= "na" })
  end

  local buf = vim.api.nvim_create_buf(false, true)
  local win = open_float(buf, " Choose your languages ",
    " j/k move   Space or click checks   Enter confirms   q decides later ", #rows)
  vim.wo[win].cursorline = true
  local unguard = guard(win, false)

  local function render()
    local lines = {}
    for _, row in ipairs(rows) do
      local box = row.status == "na" and "[-]" or (row.checked and "[x]" or "[ ]")
      table.insert(lines, string.format(" %s %-15s %s", box, row.group.label, row.group.languages))
    end
    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modifiable = false
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    for i, row in ipairs(rows) do
      local text = status_text[row.status]
      if text then
        vim.api.nvim_buf_set_extmark(buf, ns, i - 1, 0, {
          virt_text = { { text[1] .. " ", text[2] } },
          virt_text_pos = "right_align",
        })
      end
    end
  end

  local function close()
    unguard()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end

  local function toggle()
    local row = rows[vim.api.nvim_win_get_cursor(win)[1]]
    if row and row.status ~= "na" then
      row.checked = not row.checked
      render()
    end
  end

  local function confirm()
    local choices, checked = {}, {}
    for _, row in ipairs(rows) do
      choices[row.group.id] = row.checked
      if row.checked then
        table.insert(checked, row.group.id)
      end
    end
    languages.save(choices)
    close()
    if vim.fn.executable(script) == 0 then
      choices_changed()
      return
    end
    -- Install only if something the checked groups need is missing.
    -- Core tools count too, so this asks the script, not the list above.
    vim.system({ script, "--check", "--groups", table.concat(checked, " ") }, {}, function(check)
      vim.schedule(function()
        if check.code == 0 then
          write_marker(commit)
          choices_changed()
          vim.notify("Saved your languages. Mason installs their servers now.")
        else
          M.open_installer(commit, checked)
        end
      end)
    end)
  end

  local function skip()
    close()
    vim.notify("Nothing changed. :Deps opens the language list again.")
  end

  local function map(lhs, fn)
    vim.keymap.set("n", lhs, fn, { buffer = buf, nowait = true })
  end
  map("<Space>", toggle)
  map("x", toggle)
  map("<CR>", confirm)
  map("q", skip)
  map("<Esc>", skip)
  map("<LeftMouse>", function()
    local pos = vim.fn.getmousepos()
    if pos.winid == win and pos.line > 0 then
      vim.api.nvim_win_set_cursor(win, { pos.line, 0 })
      toggle()
    end
  end)

  render()
end

-- Ask the script for each group's status, then show the picker.
function M.open(commit)
  if current_win and vim.api.nvim_win_is_valid(current_win) then
    vim.api.nvim_set_current_win(current_win)
    return
  end
  if vim.fn.executable(script) == 0 then
    open_picker(commit, {})
    return
  end
  vim.system({ script, "--list" }, { text = true }, function(list)
    local statuses = {}
    for id, status in (list.stdout or ""):gmatch("(%S+) (%S+)") do
      statuses[id] = status
    end
    vim.schedule(function()
      open_picker(commit, statuses)
    end)
  end)
end

-- Once for each commit: show the picker if you have not chosen yet, if
-- the config has a new group, or if a checked group is missing.
function M.check()
  -- Async, so a check never slows startup.
  vim.system({ "git", "-C", config, "rev-parse", "HEAD" }, { text = true }, function(head)
    local commit = head.code == 0 and vim.trim(head.stdout) or nil
    vim.schedule(function()
      local choices = languages.load()
      if not choices or languages.has_new(choices) then
        M.open(commit)
        return
      end
      if not commit or read_marker() == commit or vim.fn.executable(script) == 0 then
        return
      end
      local checked = table.concat(languages.checked(choices), " ")
      vim.system({ script, "--check", "--groups", checked }, {}, function(check)
        vim.schedule(function()
          if check.code == 0 then
            write_marker(commit)
          else
            M.open(commit)
          end
        end)
      end)
    end)
  end)
end

vim.api.nvim_create_user_command("Deps", function()
  local head = vim.system({ "git", "-C", config, "rev-parse", "HEAD" }, { text = true }):wait()
  M.open(head.code == 0 and vim.trim(head.stdout) or nil)
end, { desc = "Choose your languages and install their system packages" })

vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    -- Skip headless runs such as `nvim --headless "+Lazy! sync"`.
    if #vim.api.nvim_list_uis() > 0 then
      M.check()
    end
  end,
})

return M
