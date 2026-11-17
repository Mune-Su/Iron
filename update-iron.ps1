<#
    update-iron.ps1
    Updates the Iron AI helper repo from the latest Iron-vX.Y.Z.zip,
    commits + pushes to GitHub, then deploys to Vercel.

    Local stuff preserved: .git, .vercel, node_modules, .env*

    Usage:
      & "$([Environment]::GetFolderPath('MyDocuments'))\IronWorks\Iron versions\update-iron.ps1"
    Options:
      -RepoPath  "C:\path\to\Iron"     (default: %USERPROFILE%\Projects\Iron)
      -ZipPath   "C:\path\Iron-v2.2.zip" (default: newest Iron-v*.zip in versions folder or Downloads)
      -NoPush    skip git commit/push
      -NoDeploy  skip vercel deploy
#>
[CmdletBinding()]
param(
    [string]$RepoPath = (Join-Path $env:USERPROFILE 'Projects\Iron'),
    [string]$ZipPath,
    [switch]$NoPush,
    [switch]$NoDeploy
)

$ErrorActionPreference = 'Stop'

function Write-Step($msg) { Write-Host "`n>> $msg" -ForegroundColor DarkYellow }
function Write-Ok($msg)   { Write-Host "   $msg" -ForegroundColor Green }
function Write-Warn2($msg){ Write-Host "   $msg" -ForegroundColor Yellow }

$VersionsDir = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'IronWorks\Iron versions'
$Downloads   = Join-Path $env:USERPROFILE 'Downloads'

Write-Host "=== IRON UPDATER ===" -ForegroundColor DarkYellow

# ---- 1. Find zip -------------------------------------------------------------
Write-Step "Locating Iron zip"
if (-not $ZipPath) {
    $candidates = @()
    foreach ($dir in @($VersionsDir, $Downloads)) {
        if (Test-Path $dir) {
            $candidates += Get-ChildItem -Path $dir -Filter 'Iron-v*.zip' -File -ErrorAction SilentlyContinue
        }
    }
    if (-not $candidates) { throw "No Iron-v*.zip found in '$VersionsDir' or '$Downloads'." }

    $ZipPath = ($candidates | Sort-Object {
        if ($_.BaseName -match 'Iron-v(\d+(\.\d+){0,3})') { [version]($matches[1] + $(if ($matches[1] -notmatch '\.') { '.0' })) } else { [version]'0.0' }
    }, LastWriteTime | Select-Object -Last 1).FullName
}
if (-not (Test-Path $ZipPath)) { throw "Zip not found: $ZipPath" }

$ZipName = [IO.Path]::GetFileNameWithoutExtension($ZipPath)
$Version = if ($ZipName -match 'Iron-v([\d\.]+)') { $matches[1] } else { 'unknown' }
Write-Ok "Using $ZipName (v$Version)"

# Archive a copy into the versions folder for version control
if (-not (Test-Path $VersionsDir)) { New-Item -ItemType Directory -Path $VersionsDir -Force | Out-Null }
$archived = Join-Path $VersionsDir ([IO.Path]::GetFileName($ZipPath))
if ((Resolve-Path $ZipPath).Path -ne $archived) {
    Copy-Item $ZipPath $archived -Force
    Write-Ok "Archived to $VersionsDir"
}

# ---- 2. Extract --------------------------------------------------------------
Write-Step "Extracting"
$Staging = Join-Path $env:TEMP "iron-update-$([guid]::NewGuid().ToString('N').Substring(0,8))"
Expand-Archive -Path $ZipPath -DestinationPath $Staging -Force

# If the zip contains a single top folder (Iron-v2.1\), use that as source
$top = Get-ChildItem $Staging
$Source = if ($top.Count -eq 1 -and $top[0].PSIsContainer) { $top[0].FullName } else { $Staging }
Write-Ok "Source: $Source"

# ---- 3. Sync into repo (preserve local config) -------------------------------
Write-Step "Syncing into $RepoPath"
if (-not (Test-Path $RepoPath)) {
    New-Item -ItemType Directory -Path $RepoPath -Force | Out-Null
    Write-Warn2 "Repo folder didn't exist - created it."
}

$rcArgs = @(
    $Source, $RepoPath, '/MIR',
    '/XD', '.git', '.vercel', 'node_modules',
    '/XF', '.env', '.env.local', '.env.*', 'update-iron.ps1',
    '/NFL', '/NDL', '/NJH', '/NJS', '/NP'
)
& robocopy @rcArgs | Out-Null
if ($LASTEXITCODE -ge 8) { throw "Robocopy failed (exit $LASTEXITCODE)." }
Write-Ok "Files synced (kept .git, .vercel, node_modules, .env*)"

Remove-Item $Staging -Recurse -Force -ErrorAction SilentlyContinue

Push-Location $RepoPath
try {
    # ---- 4. Git commit + push ------------------------------------------------
    if ($NoPush) {
        Write-Warn2 "Skipping git (-NoPush)"
    }
    elseif (-not (Test-Path (Join-Path $RepoPath '.git'))) {
        Write-Warn2 "No .git in repo folder - skipping push. Run 'git init' + add remote first."
    }
    else {
        Write-Step "Committing + pushing to GitHub"
        git add -A
        $changes = git status --porcelain
        if ($changes) {
            git commit -m "Iron v$Version" | Out-Null
            $branch = (git rev-parse --abbrev-ref HEAD).Trim()
            git push origin $branch
            if ($LASTEXITCODE -ne 0) { throw "git push failed." }
            Write-Ok "Pushed 'Iron v$Version' to origin/$branch"
        } else {
            Write-Ok "No changes to commit"
        }
    }

    # ---- 5. Vercel deploy ----------------------------------------------------
    if ($NoDeploy) {
        Write-Warn2 "Skipping deploy (-NoDeploy)"
    } else {
        Write-Step "Deploying to Vercel (prod)"
        npx vercel --prod --yes
        if ($LASTEXITCODE -ne 0) { throw "Vercel deploy failed." }
        Write-Ok "Deployed"
    }
}
finally {
    Pop-Location
}

Write-Host "`n=== IRON v$Version UPDATE COMPLETE ===" -ForegroundColor Green
Write-Host "Android: open the site in Chrome > refresh. If the old version sticks, close + reopen the installed app." -ForegroundColor DarkGray
