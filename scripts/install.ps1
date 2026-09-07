# saltay-kokpit · scripts/install.ps1
# Thin Windows wrapper: finds Git Bash and runs scripts/install.sh with the same arguments.
# Claude Code on Windows already requires Git for Windows, so bash.exe is normally present.
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
  $cmd = Get-Command bash.exe -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }
  $candidates = @(
    (Join-Path $env:ProgramFiles "Git\bin\bash.exe"),
    (Join-Path ${env:ProgramFiles(x86)} "Git\bin\bash.exe"),
    (Join-Path $env:LOCALAPPDATA "Programs\Git\bin\bash.exe")
  )
  foreach ($c in $candidates) { if (Test-Path $c) { return $c } }
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
