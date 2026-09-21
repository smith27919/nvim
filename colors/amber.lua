-- amber: matches the COSMIC Terminal "Amber" scheme on the workstation.
-- The terminal values are in ~/.config/cosmic/com.system76.CosmicTerm/v1/color_schemes_dark
vim.cmd.highlight("clear")
vim.g.colors_name = "amber"
vim.o.background = "dark"

local c = {
  -- bars and panels (warm amber-brown)
  line = "#2A231D",     -- current line, inactive status line
  marker = "#33291F",   -- column marker
  status = "#3A2E22",   -- active status line
  float = "#211C18",    -- popups
  select = "#4A3A2A",   -- visual selection, popup selection

  -- text
  fg = "#FFC07D",       -- foreground
  fg_bright = "#FFDCB8",-- bright foreground
  fg_dim = "#CF9C65",   -- dim foreground
  muted = "#92847D",    -- dim white
  comment = "#7A706A",
  gray = "#636363",     -- bright black

  -- accents
  red = "#E87C72",
  red_bright = "#F0A7A1",
  green = "#86C48A",
  yellow = "#EAC75C",
  yellow_bright = "#F1D992",
  blue = "#8CAFD8",
  blue_bright = "#B2C9E5",
  magenta = "#CB8CCE",
  cyan = "#68C4CC",
  cyan_bright = "#9AD7DD",
}

local groups = {
  -- editor (no Normal background, so the terminal background shows through)
  Normal = { fg = c.fg },
  NormalNC = { fg = c.fg },
  NormalFloat = { fg = c.fg, bg = c.float },
  FloatBorder = { fg = c.fg_dim, bg = c.float },
  FloatTitle = { fg = c.yellow, bg = c.float, bold = true },
  CursorLine = { bg = c.line },
  CursorLineNr = { fg = c.yellow, bold = true },
  LineNr = { fg = c.gray },
  ColorColumn = { bg = c.marker },
  SignColumn = {},
  StatusLine = { fg = c.fg, bg = c.status },
  StatusLineNC = { fg = c.muted, bg = c.line },
  WinSeparator = { fg = c.status },
  TabLine = { fg = c.muted, bg = c.line },
  TabLineSel = { fg = c.fg, bg = c.status, bold = true },
  TabLineFill = {},
  Visual = { bg = c.select },
  Search = { fg = "#1B1B1B", bg = c.yellow },
  IncSearch = { fg = "#1B1B1B", bg = c.red_bright },
  CurSearch = { link = "IncSearch" },
  MatchParen = { fg = c.cyan_bright, bold = true, underline = true },
  Pmenu = { fg = c.fg, bg = c.float },
  PmenuSel = { fg = c.fg_bright, bg = c.select, bold = true },
  PmenuSbar = { bg = c.line },
  PmenuThumb = { bg = c.gray },
  NonText = { fg = c.gray },
  Whitespace = { fg = c.gray },
  EndOfBuffer = { fg = c.gray },
  Folded = { fg = c.muted, bg = c.line },
  Directory = { fg = c.blue },
  Title = { fg = c.yellow, bold = true },
  ErrorMsg = { fg = c.red },
  WarningMsg = { fg = c.yellow },
  MoreMsg = { fg = c.green },
  Question = { fg = c.green },
  ModeMsg = { fg = c.fg_bright, bold = true },

  -- syntax
  Comment = { fg = c.comment, italic = true },
  Constant = { fg = c.yellow_bright },
  String = { fg = c.green },
  Character = { fg = c.green },
  Number = { fg = c.yellow_bright },
  Boolean = { fg = c.yellow_bright },
  Float = { fg = c.yellow_bright },
  Identifier = { fg = c.fg },
  Function = { fg = c.blue },
  Statement = { fg = c.magenta },
  Keyword = { fg = c.magenta },
  Conditional = { fg = c.magenta },
  Repeat = { fg = c.magenta },
  Operator = { fg = c.cyan_bright },
  Exception = { fg = c.red },
  PreProc = { fg = c.red_bright },
  Include = { fg = c.magenta },
  Type = { fg = c.yellow },
  StorageClass = { fg = c.yellow },
  Structure = { fg = c.yellow },
  Special = { fg = c.cyan },
  Delimiter = { fg = c.fg_dim },
  Todo = { fg = "#1B1B1B", bg = c.yellow, bold = true },
  Error = { fg = c.red },
  Underlined = { underline = true },

  -- treesitter (other captures fall back to the syntax groups above)
  ["@variable"] = { fg = c.fg },
  ["@variable.builtin"] = { fg = c.red_bright },
  ["@variable.parameter"] = { fg = c.fg_bright },
  ["@variable.member"] = { fg = c.blue_bright },
  ["@property"] = { fg = c.blue_bright },
  ["@module"] = { fg = c.fg_bright },
  ["@constructor"] = { fg = c.yellow },
  ["@function.builtin"] = { fg = c.cyan },
  ["@type.builtin"] = { fg = c.yellow },
  ["@keyword.return"] = { fg = c.red },
  ["@string.escape"] = { fg = c.cyan },
  ["@punctuation"] = { fg = c.fg_dim },
  ["@tag"] = { fg = c.magenta },
  ["@tag.attribute"] = { fg = c.yellow },
  ["@markup.heading"] = { fg = c.yellow, bold = true },
  ["@markup.link"] = { fg = c.blue, underline = true },
  ["@markup.raw"] = { fg = c.green },

  -- diagnostics
  DiagnosticError = { fg = c.red },
  DiagnosticWarn = { fg = c.yellow },
  DiagnosticInfo = { fg = c.blue },
  DiagnosticHint = { fg = c.cyan },
  DiagnosticOk = { fg = c.green },
  DiagnosticUnderlineError = { undercurl = true, sp = c.red },
  DiagnosticUnderlineWarn = { undercurl = true, sp = c.yellow },
  DiagnosticUnderlineInfo = { undercurl = true, sp = c.blue },
  DiagnosticUnderlineHint = { undercurl = true, sp = c.cyan },

  -- diffs (fugitive)
  DiffAdd = { bg = "#243024" },
  DiffChange = { bg = "#2A2A20" },
  DiffDelete = { fg = c.red, bg = "#3A2220" },
  DiffText = { bg = "#44401F" },
  Added = { fg = c.green },
  Changed = { fg = c.yellow },
  Removed = { fg = c.red },
}

for name, spec in pairs(groups) do
  vim.api.nvim_set_hl(0, name, spec)
end
