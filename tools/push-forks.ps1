#Requires -Version 5.1
<#
.SYNOPSIS
  Push oh-my-fish, packages-main, and pkg-winfish using a GitHub PAT.

.DESCRIPTION
  Set your token in the current session only (do not commit it):

    $env:GITHUB_TOKEN = 'ghp_...'
    .\tools\push-forks.ps1

  Creates chrisflory/pkg-winfish on GitHub if it does not exist yet.
#>
param(
    [string]$Token = $env:GITHUB_TOKEN
)

$ErrorActionPreference = 'Stop'

if (-not $Token) {
    Write-Error @'
GITHUB_TOKEN is not set.

In this PowerShell session, run:
  $env:GITHUB_TOKEN = 'ghp_your_token_here'
  .\tools\push-forks.ps1
'@
}

$headers = @{
    Authorization = "Bearer $Token"
    Accept        = 'application/vnd.github+json'
    'X-GitHub-Api-Version' = '2022-11-28'
}

function Ensure-GitHubRepo {
    param(
        [Parameter(Mandatory)][string]$Name,
        [string]$Description = ''
    )

    try {
        Invoke-RestMethod -Uri "https://api.github.com/repos/chrisflory/$Name" -Headers $headers | Out-Null
        Write-Host "Repo chrisflory/$Name already exists."
    }
    catch {
        if ($_.Exception.Response.StatusCode.value__ -ne 404) { throw }
        Write-Host "Creating repo chrisflory/$Name..."
        $body = @{
            name        = $Name
            description = $Description
            private     = $false
            auto_init     = $false
        } | ConvertTo-Json
        Invoke-RestMethod -Uri 'https://api.github.com/user/repos' -Method Post -Headers $headers -Body $body | Out-Null
    }
}

function Push-Repo {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Repo,
        [string]$Branch = 'master'
    )

    $pushUrl = "https://x-access-token:$Token@github.com/chrisflory/$Repo.git"
    Write-Host "Pushing chrisflory/$Repo ($Branch)..."
    git -C $Path remote set-url origin "https://github.com/chrisflory/$Repo.git"
    git -C $Path push $pushUrl $Branch
    Write-Host "Done: chrisflory/$Repo"
    Write-Host ''
}

$omf = Split-Path $PSScriptRoot -Parent
$workspace = Split-Path $omf -Parent
$packages = Join-Path $workspace 'packages-main'
$winfish = Join-Path $workspace 'pkg-winfish'

foreach ($path in @($omf, $packages, $winfish)) {
    if (-not (Test-Path "$path\.git")) {
        throw "Missing git repo: $path"
    }
}

Ensure-GitHubRepo -Name 'pkg-winfish' -Description 'WSL path translation, Cursor, and Windows Explorer helpers for Fish'

Push-Repo -Path $omf -Repo 'oh-my-fish'
Push-Repo -Path $packages -Repo 'packages-main'
Push-Repo -Path $winfish -Repo 'pkg-winfish'

Write-Host 'All three repos pushed successfully.' -ForegroundColor Green
