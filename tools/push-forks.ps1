#Requires -Version 5.1
<#
.SYNOPSIS
  Push oh-my-fish and packages-main using a GitHub PAT.

.DESCRIPTION
  Set your token in the current session only (do not commit it):

    $env:GITHUB_TOKEN = 'ghp_...'   # classic PAT
    # or
    $env:GITHUB_TOKEN = 'github_pat_...'   # fine-grained PAT

    .\tools\push-forks.ps1

  Classic PAT scopes: repo, workflow (workflow is required when pushing Actions YAML)
  Fine-grained PAT: access to chrisflory/oh-my-fish and packages-main with
                    Contents (read/write), Metadata (read), and Workflows (read/write).
#>
param(
    [string]$Token = $(if ($env:GITHUB_TOKEN) { $env:GITHUB_TOKEN } else { $env:GITHUB_PAT }),
    [string]$GitHubUser = $env:GITHUB_USER
)

$ErrorActionPreference = 'Stop'

function Fail-TokenHelp {
    Write-Error @'
GitHub rejected the token (401 Bad credentials).

Check:
  1. Token is copied fully with no extra spaces or quotes
  2. Token is not expired or revoked (GitHub -> Settings -> Developer settings)
  3. Classic PAT has the "repo" and "workflow" scopes
  4. Fine-grained PAT includes chrisflory repos with Contents and Workflows read/write

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

foreach ($path in @($omf, $packages)) {
    if (-not (Test-Path "$path\.git")) {
        throw "Missing git repo: $path"
    }
}

Push-Repo -Path $omf -Repo 'oh-my-fish' -User $gitUser -Secret $Token
Push-Repo -Path $packages -Repo 'packages-main' -User $gitUser -Secret $Token

Write-Host 'oh-my-fish and packages-main pushed successfully.' -ForegroundColor Green
