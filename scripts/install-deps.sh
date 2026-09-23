#!/usr/bin/env bash
# Installs the system packages that this Neovim config needs on Fedora.
# Mason installs the language servers itself, but many of them need a
# toolchain (go, dotnet, ruby, ...) that only dnf can supply.
#
# The script checks each group, lists what is missing, and asks before
# it installs anything. Run it again at any time; it skips what is there.

set -euo pipefail

if ! command -v dnf >/dev/null 2>&1; then
  echo "This script is for Fedora (dnf). Stopping."
  exit 1
fi

# Each group: "label|packages|what needs it"
groups=(
  "Core tools|neovim git gcc make unzip curl wget tar gzip ripgrep|Neovim plugins, Mason, Telescope"
  "Node.js|nodejs npm|Most servers: typescript, html, css, bash, yaml, json, vue, svelte, ..."
  "Python|python3|pyright, fortls, tclint"
  "Go|golang|gopls"
  "Java|java-25-openjdk-devel|jdtls, kotlin, groovy (javac builds groovy)"
  ".NET|dotnet-sdk-10.0|csharp_ls, fsautocomplete"
  "Ruby|ruby ruby-devel|ruby_lsp"
  "Rust|rust cargo|asm_lsp (built with cargo)"
  "Erlang and Elixir|erlang elixir|elp, elixirls"
  "R|R-core R-core-devel libuv-devel libxml2-devel|r_language_server (builds from source)"
  "Julia|julia|julials"
  "Perl|perl-interpreter|perlnavigator"
)

# rpm --whatprovides matches package names and names like "npm"
# that several packages provide (nodejs22-npm, nodejs24-npm, ...).
is_installed() {
  rpm -q --whatprovides "$1" >/dev/null 2>&1
}

to_install=()

for group in "${groups[@]}"; do
  IFS="|" read -r label packages needed_by <<< "$group"

  missing=()
  for pkg in $packages; do
    is_installed "$pkg" || missing+=("$pkg")
  done

  if [ ${#missing[@]} -eq 0 ]; then
    echo "[ok]      $label"
    continue
  fi

  echo "[missing] $label: ${missing[*]}"
  echo "          Needed by: $needed_by"
  read -r -p "          Install? [Y/n] " answer < /dev/tty
  case "$answer" in
    [nN]*) echo "          Skipped." ;;
    *) to_install+=("${missing[@]}") ;;
  esac
done

if [ ${#to_install[@]} -eq 0 ]; then
  echo
  echo "Nothing to install."
else
  echo
  echo "Installing: ${to_install[*]}"
  sudo dnf install -y "${to_install[@]}"
fi

echo
read -r -p "Install and update Neovim plugins now? [Y/n] " answer < /dev/tty
case "$answer" in
  [nN]*) ;;
  *) nvim --headless "+Lazy! sync" +qa ;;
esac

echo
echo "Done. Open Neovim and type :Mason to see the servers install."
