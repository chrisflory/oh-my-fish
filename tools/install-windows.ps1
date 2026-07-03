#Requires -Version 5.1
<#
.SYNOPSIS
  Checks WSL and Fish, then prints the Oh My Fish install command for this fork.
#>
param(
    [switch]$Install
)

$ErrorActionPreference = 'Stop'
$installCmd = 'curl https://raw.githubusercontent.com/chrisflory/oh-my-fish/master/bin/install | fish'

function Test-WslAvailable {
    return [bool](Get-Command wsl.exe -ErrorAction SilentlyContinue)
}

function Get-WslFishVersion {
    $output = wsl.exe -e bash -lc 'command -v fish >/dev/null 2>&1 && fish --version || echo MISSING' 2>&1
    return ($output | Out-String).Trim()
}

Write-Host 'Oh My Fish (chrisflory fork) — Windows install helper' -ForegroundColor Cyan
Write-Host ''

if (-not (Test-WslAvailable)) {
    Write-Host 'WSL is not available. Install WSL2 first:' -ForegroundColor Yellow
    Write-Host '  wsl --install'
    Write-Host ''
    Write-Host 'Then install Fish inside your Linux distro and run:'
    Write-Host "  $installCmd"
    exit 1
}

$fishVersion = Get-WslFishVersion
if ($fishVersion -eq 'MISSING' -or $fishVersion -eq '') {
    Write-Host 'WSL is available, but Fish is not installed inside it.' -ForegroundColor Yellow
    Write-Host 'Install Fish (Ubuntu/Debian example):'
    Write-Host '  wsl sudo apt update && wsl sudo apt install -y fish'
    Write-Host ''
    Write-Host 'Then run:'
    Write-Host "  wsl fish -c `"$installCmd`""
    exit 1
}

Write-Host "WSL: OK"
Write-Host "Fish: $fishVersion"
Write-Host ''
Write-Host 'Install command (run inside WSL):' -ForegroundColor Green
Write-Host "  $installCmd"
Write-Host ''
Write-Host 'Tip: keep OMF on the Linux filesystem (~/.local/share/omf), not /mnt/c/.'

if ($Install) {
    Write-Host ''
    Write-Host 'Running install in WSL...' -ForegroundColor Cyan
    wsl.exe -e bash -lc $installCmd
}
