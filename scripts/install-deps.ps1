# Installs the Windows packages that this Neovim config needs, with winget.
# The Windows twin of install-deps.sh: same groups, same arguments, same
# exit codes, so lua/core/deps.lua runs either one the same way.
#
# Windows PowerShell 5.1, so it runs on a fresh Windows 11. ASCII only:
# 5.1 reads a UTF-8 file without a BOM as ANSI.
#
#   install-deps.ps1           list what is missing, ask, install
#   install-deps.ps1 --check   no output; exit 1 if anything is missing
#   install-deps.ps1 --list    print "group status" lines (ok, missing, na)
#   --groups "go ruby"         with the above: only core and these groups,
#                              and install them without asking
#
# Run it with: powershell -NoProfile -ExecutionPolicy Bypass -File install-deps.ps1

# Not "Stop": in 5.1 that turns any stderr line of a native command into
# an error, and the checks below read native commands.
$ErrorActionPreference = "Continue"

$checkOnly = $false
$listOnly = $false
$onlyGiven = $false
$only = @()
for ($i = 0; $i -lt $args.Count; $i++) {
  switch ($args[$i]) {
    "--check" { $checkOnly = $true }
    "--list" { $listOnly = $true }
    "--groups" {
      $onlyGiven = $true
      # An empty list can arrive as a missing argument.
      if ($i + 1 -lt $args.Count -and -not "$($args[$i + 1])".StartsWith("--")) {
        $only = "$($args[$i + 1])".Split(" ", [StringSplitOptions]::RemoveEmptyEntries)
        $i++
      }
    }
  }
}
if ($listOnly) { $checkOnly = $true }

# Read PATH from the registry. Neovim keeps the PATH it started with, so it
# does not see what winget installed after that.
function Update-ProcessPath {
  $machine = [Environment]::GetEnvironmentVariable("Path", "Machine")
  $user = [Environment]::GetEnvironmentVariable("Path", "User")
  $env:Path = "$machine;$user;$env:Path"
}
Update-ProcessPath

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
  # No package manager: nothing this script can do, so do not nag on startup.
  if ($checkOnly) { exit 0 }
  Write-Host "winget not found. Install App Installer from the Microsoft Store. Stopping."
  exit 1
}

# Each group: the commands it needs, and the winget package for each one.
# "cc" is any C compiler, for the Treesitter parsers. WinLibs is MinGW-w64 GCC.
# "gzip": Mason unpacks .gz files with it (millet). Git has a gzip, but its
# usr\bin folder also has a link.exe and a find.exe, so it stays off the PATH.
# "msvc": the Visual Studio C++ tools. npm builds some servers with
# node-gyp (awk_ls), and node-gyp does not use GCC on Windows.
# A group with one pair needs the leading comma: PowerShell flattens
# @(@("go", "GoLang.Go")) into @("go", "GoLang.Go").
$DepGroups = [ordered]@{
  core   = @(@("nvim", "Neovim.Neovim"), @("git", "Git.Git"), @("rg", "BurntSushi.ripgrep.MSVC"),
             @("cc", "BrechtSanders.WinLibs.POSIX.UCRT"), @("gzip", "GnuWin32.Gzip"))
  node   = @(@("node", "OpenJS.NodeJS.LTS"), @("npm", "OpenJS.NodeJS.LTS"),
             @("msvc", "Microsoft.VisualStudio.2022.BuildTools"))
  python = , @("python", "Python.Python.3.13")
  go     = , @("go", "GoLang.Go")
  java   = , @("javac", "EclipseAdoptium.Temurin.21.JDK")
  dotnet = , @("dotnet", "Microsoft.DotNet.SDK.10")
  ruby   = , @("ruby", "RubyInstallerTeam.RubyWithDevKit.3.4")
  rust   = , @("cargo", "Rustlang.Rust.GNU")
  beam   = @(@("erl", "Erlang.ErlangOTP"), @("elixir", "Elixir.Elixir"))
  r      = , @("Rscript", "RProject.R")
  julia  = , @("julia", "Julialang.Julia")
  perl   = , @("perl", "StrawberryPerl.StrawberryPerl")
}

$Labels = @{
  core = "Core tools"; node = "Node.js"; python = "Python"; go = "Go"; java = "Java"
  dotnet = ".NET"; ruby = "Ruby"; rust = "Rust"; beam = "Erlang and Elixir"; r = "R"
  julia = "Julia"; perl = "Perl"
}

$NeededBy = @{
  core = "Neovim plugins, Mason, Telescope, Treesitter parsers, millet (gzip)"
  node = "Most servers: typescript, html, css, pyright, bash, yaml, json, vue, ...; awk_ls (C++ tools)"
  python = "fortls, tclint, black"
  go = "gopls"
  java = "jdtls, kotlin, groovy (javac builds groovy)"
  dotnet = "csharp_ls, fsautocomplete"
  ruby = "ruby_lsp"
  rust = "asm_lsp (built with cargo)"
  beam = "elp, elixirls"
  r = "r_language_server"
  julia = "julials"
  perl = "perlnavigator"
}

# Some installers do not put their bin folder on the PATH. These are the
# folders to look in, newest match first. The script adds a found folder
# to your user PATH, the way install-deps.sh links versioned names.
$BinDirs = @{
  python  = @("$env:LOCALAPPDATA\Programs\Python\Python3*")
  javac   = @("$env:ProgramFiles\Eclipse Adoptium\jdk-*\bin")
  ruby    = @("C:\Ruby3*\bin")
  cargo   = @("$env:USERPROFILE\.cargo\bin")
  erl     = @("$env:ProgramFiles\Erlang OTP\bin", "$env:ProgramFiles\erl-*\bin")
  elixir  = @("${env:ProgramFiles(x86)}\Elixir\bin", "$env:ProgramFiles\Elixir\bin")
  Rscript = @("$env:ProgramFiles\R\R-*\bin")
  julia   = @("$env:LOCALAPPDATA\Programs\Julia*\bin")
  perl    = @("C:\Strawberry\perl\bin")
  gzip    = @("${env:ProgramFiles(x86)}\GnuWin32\bin")
}

# Installer arguments for packages that need more than --silent. The
# Build Tools install nothing useful without a workload. The 2022 release,
# because every node-gyp version since 10 finds it.
$Overrides = @{
  "Microsoft.VisualStudio.2022.BuildTools" =
    "--quiet --wait --norestart --nocache --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended"
}

function Test-Have($name) {
  return [bool](Get-Command $name -CommandType Application -ErrorAction SilentlyContinue)
}

# A command is present when it exists and works. The python.exe in
# WindowsApps is a Store stub that only prints a message, so run it.
function Test-Command($name) {
  switch ($name) {
    "cc" {
      foreach ($c in "zig", "gcc", "clang", "cl", "cc") {
        if (Test-Have $c) { return $true }
      }
      return $false
    }
    "python" {
      if (-not (Test-Have "python")) { return $false }
      & python -m venv --help *> $null
      return $LASTEXITCODE -eq 0
    }
    "msvc" {
      # vswhere comes with every Visual Studio install. Ask it for the C++ tools.
      $vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
      if (-not (Test-Path $vswhere)) { return $false }
      $found = & $vswhere -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 `
        -property installationPath
      return [bool]$found
    }
    "ruby" {
      # ruby_lsp builds a native gem, so the headers must exist too.
      if (-not ((Test-Have "ruby") -and (Test-Have "gem"))) { return $false }
      & ruby -rrbconfig -e "exit File.exist?(File.join(RbConfig::CONFIG['rubyhdrdir'], 'ruby.h'))" *> $null
      return $LASTEXITCODE -eq 0
    }
    default { return Test-Have $name }
  }
}

function Test-Group($group) {
  foreach ($pair in $DepGroups[$group]) {
    if (-not (Test-Command $pair[0])) { return $false }
  }
  return $true
}

# The winget packages for the missing commands of a group, without repeats.
# Only missing ones: winget upgrades a package that is already installed,
# and an upgrade of a running Neovim fails.
function Get-MissingPackages($group) {
  $ids = @()
  foreach ($pair in $DepGroups[$group]) {
    if (-not (Test-Command $pair[0]) -and $ids -notcontains $pair[1]) { $ids += $pair[1] }
  }
  return $ids
}

# Add a folder to the user PATH in the registry, and keep the %VARIABLES%
# in it unexpanded.
function Add-UserPath($dir) {
  $key = Get-Item "HKCU:\Environment"
  $raw = $key.GetValue("Path", "", "DoNotExpandEnvironmentNames")
  if (($raw -split ";") -contains $dir) { return }
  $new = if ($raw) { "$raw;$dir" } else { $dir }
  Set-ItemProperty -Path "HKCU:\Environment" -Name Path -Value $new -Type ExpandString
  # Tell Explorer that the environment changed, so new terminals see it.
  [Environment]::SetEnvironmentVariable("NVIM_DEPS_REFRESH", "1", "User")
  [Environment]::SetEnvironmentVariable("NVIM_DEPS_REFRESH", $null, "User")
  Write-Host "Added to your PATH: $dir"
}

function Repair-Path($group) {
  Update-ProcessPath
  foreach ($pair in $DepGroups[$group]) {
    $name = $pair[0]
    if ((Test-Command $name) -or -not $BinDirs.ContainsKey($name)) { continue }
    foreach ($pattern in $BinDirs[$name]) {
      $dir = Get-Item $pattern -ErrorAction SilentlyContinue | Sort-Object Name | Select-Object -Last 1
      if ($dir) {
        Add-UserPath $dir.FullName
        if ($name -eq "python") { Add-UserPath (Join-Path $dir.FullName "Scripts") }
        Update-ProcessPath
        break
      }
    }
  }
}

function Install-Group($group) {
  foreach ($id in (Get-MissingPackages $group)) {
    Write-Host "winget install $id"
    $mode = @("--silent")
    if ($Overrides.ContainsKey($id)) {
      $mode = @("--override", $Overrides[$id])
      Write-Host "          This install is large and takes several minutes."
    }
    # Out-Host: output that is not sent to the screen becomes part of the
    # return value of this function.
    & winget install --id $id -e --source winget @mode --disable-interactivity `
      --accept-package-agreements --accept-source-agreements | Out-Host
  }
  Repair-Path $group
  # Trust the result, not the winget exit code: winget also fails for a
  # package that is installed but not on the PATH.
  return Test-Group $group
}

# With --groups, core always counts, and the rest only if listed.
function Test-Wanted($group) {
  if (-not $onlyGiven) { return $true }
  if ($group -eq "core") { return $true }
  return $only -contains $group
}

# The status of each group that you can choose, for the Neovim picker.
# winget has a package for every group, so no group is "na".
if ($listOnly) {
  foreach ($group in $DepGroups.Keys) {
    if ($group -eq "core") { continue }
    if (Test-Group $group) { Write-Output "$group ok" } else { Write-Output "$group missing" }
  }
  exit 0
}

# The policy outside this process. Undefined everywhere means Restricted,
# the Windows default. Mason runs install.ps1 for some servers (R, groovy),
# and Restricted blocks them. A security setting: tell, do not change it.
function Get-UserExecutionPolicy {
  foreach ($scope in "MachinePolicy", "UserPolicy", "CurrentUser", "LocalMachine") {
    $policy = "$(Get-ExecutionPolicy -Scope $scope)"
    if ($policy -ne "Undefined") { return $policy }
  }
  return "Restricted"
}

if (-not $checkOnly) {
  Write-Host "Package manager: winget"
  $policy = Get-UserExecutionPolicy
  if ($policy -eq "Restricted" -or $policy -eq "AllSigned") {
    Write-Host "[warning] PowerShell scripts are blocked ($policy). Mason cannot install"
    Write-Host "          some servers (R, groovy). To allow them, run this yourself:"
    Write-Host "          Set-ExecutionPolicy -Scope CurrentUser RemoteSigned"
  }
}

$selected = @()
foreach ($group in $DepGroups.Keys) {
  if (-not (Test-Wanted $group)) { continue }
  if (Test-Group $group) {
    if (-not $checkOnly) { Write-Host ("[ok]      " + $Labels[$group]) }
    continue
  }
  if ($checkOnly) { exit 1 }

  Write-Host ("[missing] " + $Labels[$group] + ": " + ((Get-MissingPackages $group) -join " "))
  Write-Host ("          Needed by: " + $NeededBy[$group])
  # The Neovim picker has already asked.
  if ($onlyGiven) {
    $selected += $group
    continue
  }
  $answer = Read-Host "          Install? [Y/n]"
  if ($answer -match "^[nN]") { Write-Host "          Skipped." } else { $selected += $group }
}

if ($checkOnly) { exit 0 }

$failed = @()
if ($selected.Count -eq 0) {
  Write-Host ""
  Write-Host "Nothing to install."
} else {
  Write-Host ""
  Write-Host "Some installers ask for administrator rights. Accept each prompt."
  # One group at a time, so one failed package fails only its own group.
  foreach ($group in $selected) {
    Write-Host ""
    Write-Host ("Installing " + $Labels[$group])
    if (-not (Install-Group $group)) { $failed += $Labels[$group] }
  }

  Write-Host ""
  if ($failed.Count -gt 0) {
    Write-Host ("Failed: " + ($failed -join ", "))
    Write-Host "Restart Neovim to try again."
  } else {
    # Inside Neovim there is no restart here, as there is on Linux: a
    # restarted Neovim keeps the old PATH. deps.lua reads the new PATH and
    # lets Mason install the servers now.
    if ($env:NVIM) {
      Write-Host "Mason installs the servers that needed these tools now."
      Write-Host "Later, close Neovim and your terminal, then open them again."
    } else {
      Write-Host "Open a new terminal, then start Neovim. Mason then installs the servers."
    }
  }
}

Write-Host ""
Read-Host "Press Enter to close" | Out-Null

# A failed group must exit non-zero, so Neovim does not mark this commit
# as checked and asks again on the next start.
if ($failed.Count -gt 0) { exit 1 }
exit 0
