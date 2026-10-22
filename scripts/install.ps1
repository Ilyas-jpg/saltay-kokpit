# saltay-kokpit · scripts/install.ps1
# Thin Windows wrapper: finds Git Bash and runs scripts/install.sh with the same arguments.
# Claude Code on Windows already requires Git for Windows, so bash.exe is normally present.
# WSL's bash.exe is skipped on purpose (it would run the installer inside Linux).
#
#   powershell -ExecutionPolicy Bypass -File scripts\install.ps1 -Lang tr
#   powershell -ExecutionPolicy Bypass -File scripts\install.ps1 -Lang en -Vault "D:\Vault"
#
# Compatible with Windows PowerShell 5.1 (no && / ternary / ?. used).
param(
  [ValidateSet("tr","en")] [string]$Lang = "tr",
  [string]$Vault = "",
  [string]$Projects = "",
  [string]$Name = "",
  [switch]$DryRun
)

$ErrorActionPreference = "Stop"

function Find-Bash {
  # Git Bash only. On machines with WSL the first bash.exe on PATH (under WindowsApps or
  # System32) is the WSL launcher: it starts Linux, where /c/... paths do not exist.
  $candidates = @()
  if ($env:CLAUDE_CODE_GIT_BASH_PATH) { $candidates += $env:CLAUDE_CODE_GIT_BASH_PATH }
  $roots = @($env:ProgramFiles, ${env:ProgramFiles(x86)})
  if ($env:LOCALAPPDATA) { $roots += (Join-Path $env:LOCALAPPDATA "Programs") }
  foreach ($root in $roots) { if ($root) { $candidates += (Join-Path $root "Git\bin\bash.exe") } }
  $git = Get-Command git.exe -ErrorAction SilentlyContinue
  if ($git) { $candidates += (Join-Path (Split-Path -Parent (Split-Path -Parent $git.Source)) "bin\bash.exe") }
  foreach ($c in $candidates) { if ($c -and (Test-Path $c)) { return $c } }
  foreach ($cmd in @(Get-Command bash.exe -All -ErrorAction SilentlyContinue)) {
    if ($cmd.Source -notmatch '\\(WindowsApps|System32)\\') { return $cmd.Source }
  }
  return $null
}

function To-BashPath([string]$p) {
  if ([string]::IsNullOrEmpty($p)) { return "" }
  $full = [System.IO.Path]::GetFullPath($p)
  $drive = $full.Substring(0,1).ToLower()
  $rest = $full.Substring(2) -replace "\\", "/"
  return "/$drive$rest"
}

$bash = Find-Bash
if (-not $bash) {
  Write-Host "Git Bash not found. Install Git for Windows (https://git-scm.com/download/win) and retry." -ForegroundColor Red
  Write-Host "(WSL's bash.exe is not used: it runs Linux, where Windows paths do not exist. Set CLAUDE_CODE_GIT_BASH_PATH if Git lives elsewhere.)" -ForegroundColor DarkGray
  exit 1
}

$repo = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$script = To-BashPath (Join-Path $repo "scripts\install.sh")

$bashArgs = @($script, "--lang", $Lang)
if ($Vault -ne "")    { $bashArgs += @("--vault", (To-BashPath $Vault)) }
if ($Projects -ne "") { $bashArgs += @("--projects", (To-BashPath $Projects)) }
if ($Name -ne "")     { $bashArgs += @("--name", $Name) }
if ($DryRun)          { $bashArgs += "--dry-run" }

Write-Host "running: bash $($bashArgs -join ' ')" -ForegroundColor DarkGray
& $bash @bashArgs
exit $LASTEXITCODE
