# saltay-kokpit · scripts/install.ps1
# Thin Windows wrapper: finds Git Bash and runs scripts/install.sh with the same arguments.
# Claude Code on Windows already requires Git for Windows, so bash.exe is normally present.
# WSL's bash.exe is skipped on purpose (it would run the installer inside Linux).
#
#   powershell -ExecutionPolicy Bypass -File scripts\install.ps1 -Lang tr
#   powershell -ExecutionPolicy Bypass -File scripts\install.ps1 -Lang en -Vault "D:\Vault"
#   powershell -ExecutionPolicy Bypass -File scripts\install.ps1 -Vault "C:\My Vault" -Layout folders -NoProjects
#
# Compatible with Windows PowerShell 5.1 (no && / ternary / ?. used).
param(
  [ValidateSet("tr","en")] [string]$Lang = "tr",
  [string]$Vault = "",
  [ValidateSet("auto","flat","folders")] [string]$Layout = "auto",
  [string]$CoreNotes = "",
  [string]$Projects = "",
  [switch]$NoProjects,
  [string]$ClaudeHome = "",
  [string]$Name = "",
  [switch]$DisableBackgroundTasks,
  [switch]$Uninstall,
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
  if ($full.StartsWith("\\")) { return ($full -replace "\\", "/") }   # UNC: //server/share/...
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
if ($Uninstall) {
  $script = To-BashPath (Join-Path $repo "scripts\uninstall.sh")
  $bashArgs = @($script)
  if ($ClaudeHome -ne "") { $bashArgs += @("--claude-home", (To-BashPath $ClaudeHome)) }
  if ($DryRun)            { $bashArgs += "--dry-run" }
} else {
  $script = To-BashPath (Join-Path $repo "scripts\install.sh")
  $bashArgs = @($script, "--lang", $Lang, "--layout", $Layout)
  if ($Vault -ne "")      { $bashArgs += @("--vault", (To-BashPath $Vault)) }
  if ($CoreNotes -ne "")  { $bashArgs += @("--core-notes", $CoreNotes) }
  if ($NoProjects)        { $bashArgs += "--no-projects" }
  elseif ($Projects -ne "") { $bashArgs += @("--projects", (To-BashPath $Projects)) }
  if ($ClaudeHome -ne "") { $bashArgs += @("--claude-home", (To-BashPath $ClaudeHome)) }
  if ($Name -ne "")       { $bashArgs += @("--name", $Name) }
  if ($DisableBackgroundTasks) { $bashArgs += "--disable-background-tasks" }
  if ($DryRun)            { $bashArgs += "--dry-run" }
}

Write-Host "running: bash $($bashArgs -join ' ')" -ForegroundColor DarkGray
& $bash @bashArgs
exit $LASTEXITCODE
