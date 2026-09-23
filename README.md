# Neovim config

A Neovim config with completion and language servers for about 40 languages.
It works on Linux, FreeBSD, OpenBSD, and NetBSD.

- **Plugins:** lazy.nvim
- **Language servers:** Mason, or the system packages on the BSDs
- **Completion:** blink.cmp, which you can turn off while you learn
- **Search:** Telescope
- **Syntax colors:** nvim-treesitter

## Requirements

- **Neovim 0.11 or newer.** Some distributions ship an older version. For example,
  Debian stable does. Type `nvim --version` to see your version. If it is older than
  0.11, get Neovim from https://github.com/neovim/neovim/releases.
- **git**

The dependency check installs the rest (see below).

## Install

1. If you already have a Neovim config, move it:

   ```
   mv ~/.config/nvim ~/.config/nvim.bak
   ```

2. Clone this repo:

   ```
   git clone https://github.com/smith27919/nvim.git ~/.config/nvim
   ```

3. Start Neovim:

   ```
   nvim
   ```

At the first start:

- lazy.nvim installs the plugins.
- Mason installs the language servers. Type `:Mason` to see the progress.
- If system packages are missing, a split opens at the bottom and asks
  to install them. When the install is done, restart Neovim.

## Your folder

The config is in `lua/core/`. At the first start, Neovim makes a link named for your
user, `lua/<username>`, that points to `lua/core/`. Git ignores the link.

A `.` in a user name becomes `_`, because Lua uses `.` to separate module names. For
example, the user `jo.smith` gets `lua/jo_smith`.

## Your own settings

Git ignores these paths, so you can change them. A `git pull` does not
change them:

| Path | Use |
| --- | --- |
| `lua/overrides/init.lua` | Settings for your machine. Neovim loads this file last. |
| `lua/overrides/plugins/` | More plugins, in the same format as `lua/core/plugins/` |
| `colors/` | Your own colorschemes |

The config has no colorscheme. To add one, for example catppuccin, make
`lua/overrides/plugins/colors.lua` with this content:

```lua
return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd.colorscheme("catppuccin")
    end,
  },
}
```

## Dependency check

`scripts/install-deps.sh` checks for the system packages that the language servers
need, such as Go, Java, .NET, Ruby, Rust, and R. For each missing group, it
asks before it installs anything.

- Neovim runs the check once after each new commit or `git pull`. The check runs in
  the background. If nothing is missing, you see nothing.
- To run the check again, delete `~/.local/state/nvim/deps-checked`, or
  run the script yourself: `~/.config/nvim/scripts/install-deps.sh`
- The script uses `sudo`. If `sudo` is not installed, it uses `doas`, and then `su`.
- The script installs one group at a time. If one group fails, the other groups
  continue.

The script finds the package manager itself:

| System | Package manager |
| --- | --- |
| Fedora | dnf |
| Debian, Ubuntu | apt |
| Arch | pacman |
| openSUSE | zypper |
| FreeBSD | pkg |
| OpenBSD | pkg_add |
| NetBSD | pkgin |

If a system has no package for a group, the script shows `[n/a]` and skips it.

### Notes for the BSDs

- **Servers from the system packages.** About 20 servers have builds only for
  Linux, macOS, and Windows, so Mason skips them on the BSDs. The script installs
  the ones that the BSD package collection has:
  - FreeBSD: clangd (from `llvm`), lua-language-server, rust-analyzer, zls,
    terraform-ls, neocmakelsp
  - OpenBSD: clangd (from `clang-tools-extra`), lua-language-server,
    rust-analyzer, terraform-ls
  - NetBSD: clangd (from `clang-tools-extra`)

  Neovim enables each server in the list whose command is on the PATH.
- **Commands with a version in the name.** OpenBSD installs `ruby34`, `erl28`,
  and a JDK outside the PATH. NetBSD installs `python3.13`, `go126`, and a JDK
  outside the PATH. The language servers need the plain names, so the script
  makes links such as `ruby -> ruby34`. The script does not replace a command
  that already exists.
- **OpenBSD:** to use `doas`, `/etc/doas.conf` must allow your user. `pkg_add` asks
  which version to install when a package has several.
- **NetBSD:** blink.cmp has no fast matcher build for NetBSD, so it uses its Lua
  matcher. Completion works the same, but it is slower in very large files.
- **Not available on the BSDs:** .NET on OpenBSD and NetBSD, and Julia on all three.

## Language servers

The list is in `lua/core/plugins/lsp.lua`. To add a server, add its name to the
list. The names are in `:help lspconfig-all`.

These languages have no server in this config:

- **No server available:** Visual Basic, Delphi, Scratch, Prolog, Lisp, SAS, ABAP
- **Not in Mason:** Swift, Dart, Scala
- **Need extra setup:** MATLAB, PowerShell, Haskell, OCaml

## Keyboard shortcuts

The leader key is **Space**. For example, `<leader>ff` means push Space, then `f`, then `f`.

To search all shortcuts from Neovim, push `<leader>fkm`.

### Files and search (Telescope)

| Keys | Action |
| --- | --- |
| `<leader>ff` | Find files, hidden files included |
| `<leader>fg` | Find files that git tracks |
| `<leader>fs` | Search for text in all files |
| `<leader>fd` | Open the file explorer (netrw) |
| `<leader>fc` | List commands |
| `<leader>fh` | List command history |
| `<leader>fv` | List Vim options |
| `<leader>fkm` | List keyboard shortcuts |

In a Telescope window:

| Keys | Action |
| --- | --- |
| `Ctrl+n` / `Ctrl+p` | Next / previous result |
| `Enter` | Open the result |
| `Ctrl+x` / `Ctrl+v` / `Ctrl+t` | Open in a horizontal split / vertical split / tab |
| `Ctrl+u` / `Ctrl+d` | Scroll the preview up / down |
| `Ctrl+q` | Send all results to the quickfix list |
| `Ctrl+/` | Show the Telescope keys |
| `Esc` twice | Close |

### Harpoon (quick file marks)

| Keys | Action |
| --- | --- |
| `<leader>a` | Mark the current file |
| `Ctrl+e` | Open the list of marked files |
| `Ctrl+h` / `Ctrl+j` / `Ctrl+k` / `Ctrl+l` | Go to marked file 1 / 2 / 3 / 4 |

### Completion (insert mode)

| Keys | Action |
| --- | --- |
| `<leader>tc` | Turn completion off and on (normal mode). It starts on. |
| `Tab` | Accept the item. In a snippet, go to the next field. |
| `Shift+Tab` | In a snippet, go to the previous field |
| `Ctrl+n` / `Ctrl+p` or `Down` / `Up` | Next / previous item |
| `Ctrl+Space` | Open the menu, or show the documentation |
| `Ctrl+e` | Close the menu |
| `Ctrl+b` / `Ctrl+f` | Scroll the documentation up / down |
| `Ctrl+k` | Show the function arguments |

`<leader>tc` affects all files and all languages. Completion is on again each time
Neovim starts. To make it start off, set `vim.g.completion_enabled = false` in
`lua/overrides/init.lua`.

### Language server (Neovim built-in)

| Keys | Action |
| --- | --- |
| `K` | Show the documentation for the item under the cursor |
| `grn` | Rename the item everywhere |
| `grr` | List all references |
| `gri` | Go to the implementation |
| `grt` | Go to the type definition |
| `gra` | Show the fixes and code actions |
| `gO` | List the symbols in the file |
| `]d` / `[d` | Go to the next / previous error |
| `Ctrl+w d` | Show the error under the cursor |
| `Ctrl+s` | Show the function arguments (insert mode) |

### Editing

| Keys | Action |
| --- | --- |
| `J` / `K` | Move the selected lines down / up (visual mode) |
| `<leader>u` | Open the undo tree |
| `<leader>x` | Make the current file executable (`chmod +x`) |

### Git (Fugitive)

| Keys | Action |
| --- | --- |
| `<leader>gs` | Open the git status window |

In the git status window:

| Keys | Action |
| --- | --- |
| `s` / `u` | Stage / unstage the file under the cursor |
| `=` | Show the changes in the file |
| `cc` | Commit |
| `g?` | Show the Fugitive keys |
