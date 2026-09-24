#!/bin/sh
# Installs the system packages that this Neovim config needs.
# Mason installs the language servers itself, but many of them need a
# toolchain (go, dotnet, ruby, ...) that only the system can supply.
#
# POSIX sh, so it runs on the BSDs without bash. Supported package
# managers: dnf, apt, pacman, zypper, pkg (FreeBSD), pkg_add (OpenBSD),
# pkgin (NetBSD). The BSD package names were checked against the
# FreeBSD 15, OpenBSD 7.9, and NetBSD 10.1 package indexes.
#
# Neovim runs this once after each git pull (see lua/core/deps.lua).
#   install-deps.sh           list what is missing, ask, install
#   install-deps.sh --check   no output; exit 1 if anything is missing
# Inside Neovim, exit 10 after an install means "restart Neovim now".

set -eu

check_only=false
[ "${1:-}" = "--check" ] && check_only=true

have() {
  for cmd in "$@"; do
    command -v "$cmd" >/dev/null 2>&1 || return 1
  done
}

# Pick the package manager. The BSDs are matched by uname, because
# "pkg" is a common name for other tools on Linux.
case "$(uname -s)" in
  FreeBSD) have pkg && PM=pkg ;;
  OpenBSD) have pkg_add && PM=pkg_add ;;
  NetBSD) have pkgin && PM=pkgin ;;
  *)
    if have dnf; then PM=dnf
    elif have apt-get; then PM=apt
    elif have pacman; then PM=pacman
    elif have zypper; then PM=zypper
    fi
    ;;
esac

if [ -z "${PM:-}" ]; then
  # Unknown system: nothing this script can do, so do not nag on startup.
  $check_only && exit 0
  echo "No supported package manager found. Stopping."
  exit 1
fi

DEP_GROUPS="core node python go java dotnet ruby rust beam r julia perl servers"

label() {
  case $1 in
    core) echo "Core tools" ;;
    node) echo "Node.js" ;;
    python) echo "Python" ;;
    go) echo "Go" ;;
    java) echo "Java" ;;
    dotnet) echo ".NET" ;;
    ruby) echo "Ruby" ;;
    rust) echo "Rust" ;;
    beam) echo "Erlang and Elixir" ;;
    r) echo "R" ;;
    julia) echo "Julia" ;;
    perl) echo "Perl" ;;
    servers) echo "Language servers from $PM" ;;
  esac
}

needed_by() {
  case $1 in
    core) echo "Neovim plugins, Mason, Telescope" ;;
    node) echo "Most servers: typescript, html, css, bash, yaml, json, vue, ..." ;;
    python) echo "pyright, fortls, tclint" ;;
    go) echo "gopls" ;;
    java) echo "jdtls, kotlin, groovy (javac builds groovy)" ;;
    dotnet) echo "csharp_ls, fsautocomplete" ;;
    ruby) echo "ruby_lsp" ;;
    rust) echo "asm_lsp (built with cargo)" ;;
    beam) echo "elp, elixirls" ;;
    r) echo "r_language_server (builds from source)" ;;
    julia) echo "julials" ;;
    perl) echo "perlnavigator" ;;
    servers) echo "Servers and formatters that Mason has no build for on this system" ;;
  esac
}

# NetBSD installs Python as python3.13 with no python3. Mason finds the
# versioned name itself.
have_python3() {
  for py in python3 python3.14 python3.13 python3.12 python3.11; do
    if have "$py" && "$py" -m venv --help >/dev/null 2>&1; then
      return 0
    fi
  done
  return 1
}

# Commands for the "servers" group. Mason has no BSD build for these.
# shfmt is the shell formatter for format-on-save.
server_commands() {
  case $PM in
    pkg) echo "clangd lua-language-server rust-analyzer zls terraform-ls neocmakelsp shfmt" ;;
    pkg_add) echo "clangd lua-language-server rust-analyzer terraform-ls shfmt" ;;
    pkgin) echo "clangd shfmt" ;;
    *) echo "" ;;
  esac
}

# A group is present when its commands (and headers, where a server
# builds from source) exist. This works the same on every system,
# whatever the packages are called.
present() {
  case $1 in
    core) have nvim git cc make curl unzip tar gzip rg ;;
    node) have node npm ;;
    python) have_python3 ;;
    go) have go ;;
    java) have javac ;;
    dotnet) have dotnet ;;
    ruby)
      have ruby gem &&
        ruby -e 'exit File.exist?(File.join(RbConfig::CONFIG["rubyhdrdir"], "ruby.h"))'
      ;;
    rust) have cargo ;;
    beam) have erl elixir ;;
    r)
      have Rscript pkg-config &&
        Rscript -e 'quit(status = as.integer(!file.exists(file.path(R.home("include"), "R.h"))))' \
          >/dev/null 2>&1 &&
        pkg-config --exists libuv libxml-2.0
      ;;
    julia) have julia ;;
    perl) have perl ;;
    servers)
      # Word splitting on the list is intended.
      # shellcheck disable=SC2046
      have $(server_commands)
      ;;
  esac
}

# Package names for each manager. Empty means the manager has no
# package for it, and the group is skipped. On OpenBSD, "name%branch"
# picks one version, and "unzip--" is the plain flavor.
packages() {
  case "$PM:$1" in
    dnf:core | apt:core | pacman:core | zypper:core)
      echo "neovim git gcc make curl unzip tar gzip ripgrep" ;;
    pkg:core) echo "neovim git gmake curl ripgrep" ;;
    pkg_add:core) echo "neovim git gmake curl unzip-- ripgrep" ;;
    pkgin:core) echo "neovim git gmake curl unzip ripgrep" ;;

    dnf:node | apt:node | pacman:node) echo "nodejs npm" ;;
    zypper:node) echo "nodejs-default npm-default" ;;
    pkg:node) echo "node npm" ;;
    pkg_add:node) echo "node" ;;
    pkgin:node) echo "nodejs" ;;

    dnf:python | zypper:python | pkg:python) echo "python3" ;;
    apt:python) echo "python3 python3-venv" ;;
    pacman:python) echo "python" ;;
    pkg_add:python) echo "python%3" ;;
    pkgin:python) echo "python313" ;;

    dnf:go) echo "golang" ;;
    apt:go) echo "golang-go" ;;
    *:go) echo "go" ;;

    dnf:java) echo "java-25-openjdk-devel" ;;
    apt:java) echo "default-jdk" ;;
    pacman:java) echo "jdk-openjdk" ;;
    zypper:java) echo "java-21-openjdk-devel" ;;
    pkg:java | pkgin:java) echo "openjdk21" ;;
    pkg_add:java) echo "jdk%21" ;;

    dnf:dotnet) echo "dotnet-sdk-10.0" ;;
    apt:dotnet) echo "dotnet-sdk-8.0" ;;
    pacman:dotnet) echo "dotnet-sdk" ;;
    pkg:dotnet) echo "dotnet8" ;;
    *:dotnet) echo "" ;;

    dnf:ruby | zypper:ruby) echo "ruby ruby-devel" ;;
    apt:ruby) echo "ruby-full" ;;
    pkg_add:ruby) echo "ruby%3.4" ;;
    *:ruby) echo "ruby" ;;

    dnf:rust | zypper:rust) echo "rust cargo" ;;
    apt:rust) echo "cargo" ;;
    *:rust) echo "rust" ;;

    pkg_add:beam) echo "erlang%28 elixir" ;;
    *:beam) echo "erlang elixir" ;;

    dnf:r) echo "R-core R-core-devel libuv-devel libxml2-devel pkgconf" ;;
    apt:r) echo "r-base r-base-dev libuv1-dev libxml2-dev pkg-config" ;;
    pacman:r) echo "r libuv libxml2 pkgconf" ;;
    zypper:r) echo "R-base R-base-devel libuv-devel libxml2-devel pkgconf" ;;
    pkg:r) echo "R libuv libxml2 pkgconf gmake" ;;
    pkg_add:r) echo "R libuv libxml" ;;
    pkgin:r) echo "R libuv libxml2 pkgconf" ;;

    apt:julia | pkg:julia | pkg_add:julia | pkgin:julia) echo "" ;;
    *:julia) echo "julia" ;;

    dnf:perl) echo "perl-interpreter" ;;
    pkg:perl) echo "perl5" ;;
    pkg_add:perl) echo "" ;;
    *:perl) echo "perl" ;;

    pkg:servers) echo "llvm lua-language-server rust-analyzer zls terraform-ls neocmakelsp shfmt" ;;
    pkg_add:servers) echo "clang-tools-extra lua-language-server rust-analyzer terraform-ls shfmt" ;;
    pkgin:servers) echo "clang-tools-extra shfmt" ;;
    *:servers) echo "" ;;
  esac
}

# Run as root directly, else through sudo, doas (OpenBSD), or su.
if [ "$(id -u)" -eq 0 ]; then
  ROOT_TOOL=none
elif have sudo; then
  ROOT_TOOL=sudo
elif have doas; then
  ROOT_TOOL=doas
else
  ROOT_TOOL=su
fi

as_root() {
  case $ROOT_TOOL in
    none) "$@" ;;
    sudo) sudo "$@" ;;
    doas) doas "$@" ;;
    su) su root -c "$*" ;;
  esac
}

install() {
  case $PM in
    dnf) as_root dnf install -y "$@" ;;
    apt) as_root apt-get install -y "$@" ;;
    pacman) as_root pacman -S --needed --noconfirm "$@" ;;
    zypper) as_root zypper install -y "$@" ;;
    pkg) as_root pkg install -y "$@" ;;
    pkg_add) as_root pkg_add "$@" ;;
    pkgin) as_root pkgin -y install "$@" ;;
  esac
}

# link NAME TARGET: make NAME a command when only a versioned copy exists.
link() {
  [ -n "$2" ] && [ -e "$2" ] || return 0
  have "$1" && return 0
  as_root ln -s "$2" "$BIN/$1" && echo "Linked $BIN/$1 -> $2"
}

# The last match of a pattern, or nothing.
newest() {
  # Globbing on $1 is intended.
  # shellcheck disable=SC2012,SC2086
  ls -d $1 2>/dev/null | tail -n 1
}

# OpenBSD and NetBSD install some commands with the version in the name
# (ruby34, erl28, go126) or outside the PATH (the JDKs). The servers need
# the plain names. OpenBSD's own Ruby package message gives these links.
link_versioned() {
  case $PM in
    pkg_add)
      BIN=/usr/local/bin
      ruby=$(newest "$BIN/ruby[0-9][0-9]")
      if [ -n "$ruby" ]; then
        v=${ruby#"$BIN/ruby"}
        for c in ruby gem bundle bundler erb irb rake rdoc ri; do
          link "$c" "$BIN/$c$v"
        done
      fi
      erl=$(newest "$BIN/erl[0-9][0-9]")
      if [ -n "$erl" ]; then
        v=${erl#"$BIN/erl"}
        for c in erl erlc escript; do
          link "$c" "$BIN/$c$v"
        done
      fi
      jdk=$(newest "/usr/local/jdk-[0-9]*")
      if [ -n "$jdk" ]; then
        link java "$jdk/bin/java"
        link javac "$jdk/bin/javac"
      fi
      ;;
    pkgin)
      BIN=/usr/pkg/bin
      link python3 "$(newest "$BIN/python3.[0-9]*[0-9]")"
      go=$(newest "$BIN/go[0-9][0-9][0-9]")
      if [ -n "$go" ]; then
        v=${go#"$BIN/go"}
        link go "$BIN/go$v"
        link gofmt "$BIN/gofmt$v"
      fi
      jdk=$(newest "/usr/pkg/java/openjdk[0-9]*")
      if [ -n "$jdk" ]; then
        link java "$jdk/bin/java"
        link javac "$jdk/bin/javac"
      fi
      ;;
  esac
}

$check_only || echo "Package manager: $PM"

selected=""
for group in $DEP_GROUPS; do
  # Only the BSDs need servers from the system packages.
  if [ "$group" = servers ] && [ -z "$(packages servers)" ]; then
    continue
  fi

  if present "$group"; then
    $check_only || echo "[ok]      $(label "$group")"
    continue
  fi

  names=$(packages "$group")
  if [ -z "$names" ]; then
    # No package on this system: do not open the installer for it.
    $check_only || echo "[n/a]     $(label "$group"): no $PM package"
    continue
  fi

  $check_only && exit 1

  echo "[missing] $(label "$group"): $names"
  echo "          Needed by: $(needed_by "$group")"
  printf "          Install? [Y/n] "
  read -r answer
  case "$answer" in
    [nN]*) echo "          Skipped." ;;
    *) selected="$selected $group" ;;
  esac
done

$check_only && exit 0

if [ -z "$selected" ]; then
  echo
  echo "Nothing to install."
else
  if [ "$PM" = apt ]; then as_root apt-get update; fi

  # One group at a time, so a package name this system does not know
  # fails only its own group.
  failed=""
  for group in $selected; do
    echo
    echo "Installing $(label "$group"): $(packages "$group")"
    # Word splitting on the list is intended.
    # shellcheck disable=SC2046
    install $(packages "$group") || failed="$failed, $(label "$group")"
  done

  link_versioned

  echo
  if [ -n "$failed" ]; then
    echo "Failed:${failed#,}"
    echo "Restart Neovim to try again."
  else
    # Neovim sets $NVIM in its terminals. There, exit 10 asks Neovim to
    # restart, so Mason finds the new tools.
    if [ -n "${NVIM:-}" ]; then
      printf "Restart Neovim now? Mason then installs the servers that needed these tools. [Y/n] "
      read -r answer
      case "$answer" in
        [nN]*) exit 0 ;;
        *) exit 10 ;;
      esac
    fi
    echo "Restart Neovim. Mason then installs the servers that needed these tools."
  fi
fi

echo
printf "Press Enter to close."
read -r _

# A failed group must exit non-zero, so Neovim does not mark this commit
# as checked and asks again on the next start.
if [ -n "${failed:-}" ]; then
  exit 1
fi
