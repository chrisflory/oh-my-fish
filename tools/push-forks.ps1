#Requires -Version 5.1
<#
.SYNOPSIS
  Push oh-my-fish, packages-main, and pkg-winfish using a GitHub PAT.

.DESCRIPTION
  Set your token in the current session only (do not commit it):

    $env:GITHUB_TOKEN = 'ghp_...'   # classic PAT
    # or
    $env:GITHUB_TOKEN = 'github_pat_...'   # fine-grained PAT

    .\tools\push-forks.ps1

  Classic PAT scopes: repo
  Fine-grained PAT: access to chrisflory/oh-my-fish, packages-main, pkg-winfish
                    with Contents (read/write) and Metadata (read).
                    For auto-create of pkg-winfish, also needs Administration (read/write).

  If repo creation fails, create https://github.com/new named pkg-winfish and run:
    .\tools\push-forks.ps1 -SkipRepoCreate
#>
param(
    [string]$Token = $(if ($env:GITHUB_TOKEN) { $env:GITHUB_TOKEN } else { $env:GITHUB_PAT }),
    [string]$GitHubUser = $env:GITHUB_USER,
    [switch]$SkipRepoCreate
)

$ErrorActionPreference = 'Stop'

function Fail-TokenHelp {
    Write-Error @'
GitHub rejected the token (401 Bad credentials).

Check:
  1. Token is copied fully with no extra spaces or quotes
  2. Token is not expired or revoked (GitHub -> Settings -> Developer settings)
  3. Classic PAT has the "repo" scope
  4. Fine-grained PAT includes chrisflory repos with Contents read/write

Set token in THIS PowerShell window before running:
  $env:GITHUB_TOKEN = 'ghp_...'
  .\tools\push-forks.ps1

Optional: pass username used for git HTTPS (defaults to API login):
  $env:GITHUB_USER = 'chrisflory'
'@
}

if (-not $Token) {
    Write-Error @'
GITHUB_TOKEN is not set.

In this PowerShell session, run:
  $env:GITHUB_TOKEN = 'ghp_your_token_here'
  .\tools\push-forks.ps1
'@
}

$Token = $Token.Trim().Trim('"').Trim("'")

if ($Token.Length -lt 20) {
    Write-Error "Token looks too short ($($Token.Length) chars). Paste the full PAT from GitHub."
}

function Get-GitHubHeaders {
    param([string]$Value)

    # Classic PATs (ghp_) and fine-grained (github_pat_) both accept Bearer.
    return @{
        Authorization          = "Bearer $Value"
        Accept                 = 'application/vnd.github+json'
        'X-GitHub-Api-Version' = '2022-11-28'
    }
}

function Test-GitHubToken {
    param([hashtable]$Headers)

    try {
        $user = Invoke-RestMethod -Uri 'https://api.github.com/user' -Headers $Headers
        Write-Host "Authenticated as $($user.login)"
        return $user.login
    }
    catch {
        Fail-TokenHelp
    }
}

function Ensure-GitHubRepo {
    param(
        [Parameter(Mandatory)][hashtable]$Headers,
        [Parameter(Mandatory)][string]$Owner,
        [Parameter(Mandatory)][string]$Name,
        [string]$Description = ''
    )

    $checkUri = "https://api.github.com/repos/$Owner/$Name"
    try {
        Invoke-RestMethod -Uri $checkUri -Headers $Headers | Out-Null
        Write-Host "Repo $Owner/$Name already exists."
        return
    }
    catch {
        $status = $null
        if ($_.Exception.Response) {
            $status = [int]$_.Exception.Response.StatusCode
        }
        if ($status -ne 404) {
            if ($status -eq 401) { Fail-TokenHelp }
            throw $_
        }
    }

    Write-Host "Creating repo $Owner/$Name..."
    $body = @{
        name        = $Name
        description = $Description
        private     = $false
        auto_init   = $false
    } | ConvertTo-Json
    try {
        Invoke-RestMethod -Uri 'https://api.github.com/user/repos' -Method Post -Headers $Headers -Body $body | Out-Null
    }
    catch {
        Write-Warning @"
Could not create $Owner/$Name via API.

Create it manually: https://github.com/new
  Owner: $Owner
  Name:  $Name

Then rerun: .\tools\push-forks.ps1 -SkipRepoCreate
"@
        throw
    }
}

function Push-Repo {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Repo,
        [Parameter(Mandatory)][string]$User,
        [Parameter(Mandatory)][string]$Secret,
        [string]$Branch = 'master'
    )

    $pushUrl = "https://${User}:$Secret@github.com/chrisflory/$Repo.git"
    Write-Host "Pushing chrisflory/$Repo ($Branch)..."
    git -C $Path remote set-url origin "https://github.com/chrisflory/$Repo.git"
    git -C $Path push $pushUrl $Branch 2>&1 | ForEach-Object { Write-Host $_ }
    if ($LASTEXITCODE -ne 0) {
        throw "git push failed for chrisflory/$Repo (exit $LASTEXITCODE)"
    }
    Write-Host "Done: chrisflory/$Repo"
    Write-Host ''
}

$headers = Get-GitHubHeaders -Value $Token
$login = Test-GitHubToken -Headers $headers
$gitUser = if ($GitHubUser) { $GitHubUser.Trim() } else { $login }

$omf = Split-Path $PSScriptRoot -Parent
$workspace = Split-Path $omf -Parent
$packages = Join-Path $workspace 'packages-main'
$winfish = Join-Path $workspace 'pkg-winfish'

foreach ($path in @($omf, $packages, $winfish)) {
    if (-not (Test-Path "$path\.git")) {
        throw "Missing git repo: $path"
    }
}

if (-not $SkipRepoCreate) {
    Ensure-GitHubRepo -Headers $headers -Owner 'chrisflory' -Name 'pkg-winfish' `
        -Description 'WSL path translation, Cursor, and Windows Explorer helpers for Fish'
}
else {
    Write-Host 'Skipping pkg-winfish repo creation (-SkipRepoCreate).'
}

Push-Repo -Path $omf -Repo 'oh-my-fish' -User $gitUser -Secret $Token
Push-Repo -Path $packages -Repo 'packages-main' -User $gitUser -Secret $Token
Push-Repo -Path $winfish -Repo 'pkg-winfish' -User $gitUser -Secret $Token

Write-Host 'All three repos pushed successfully.' -ForegroundColor Green
