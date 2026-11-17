# update-iron.ps1 - replace the Iron repo with the newest Iron-vX.Y.Z version.
# Lives in the repo root and works on any PC: no hard-coded user paths.
#  1. Moves the newest Iron-v*.zip from Downloads into Documents\IronWorks\Iron versions.
#  2. Picks the newest version there (zip or folder) and extracts it if needed.
#  3. Replaces everything in the repo EXCEPT the items in $keep.
#  4. Runs git add and shows git status. It does NOT commit or push.

$repo      = $PSScriptRoot
$versions  = Join-Path (New-Object -ComObject Shell.Application).NameSpace('shell:Personal').Self.Path 'IronWorks\Iron versions'
$downloads = (New-Object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path
$keep      = '.git', '.vercel', '.gitignore', '.vercelignore', '.env', '.env.local', 'node_modules', 'update-iron.ps1'

function VersionOf($item) {
  if ($item.Name -match 'v(\d+\.\d+\.\d+)') { [version]$Matches[1] } else { [version]'0.0.0' }
}
function Stop-Update($msg) { Write-Host $msg -ForegroundColor Red; exit 1 }

if (-not (Test-Path (Join-Path $repo '.git'))) { Stop-Update "$repo is not a Git repo - keep this script in the Iron repo folder." }
if (-not (Test-Path $versions)) { New-Item -ItemType Directory $versions -Force | Out-Null; Write-Host "Created $versions" }
Write-Host "Repo:     $repo" -ForegroundColor DarkGray
Write-Host "Versions: $versions" -ForegroundColor DarkGray

# 1. a new zip in Downloads goes into the versions folder
$dl = Get-ChildItem $downloads -Filter 'Iron-v*.zip' -ErrorAction SilentlyContinue |
  Sort-Object { VersionOf $_ } -Descending | Select-Object -First 1
if ($dl) {
  $dest = Join-Path $versions ("Iron-v{0}.zip" -f (VersionOf $dl))
  Move-Item $dl.FullName $dest -Force
  Write-Host "Moved $($dl.Name) from Downloads into Iron versions"
}

# 2. newest version in the versions folder
$latest = Get-ChildItem $versions -Filter 'Iron-v*' |
  Where-Object { $_.PSIsContainer -or $_.Extension -eq '.zip' } |
  Sort-Object { VersionOf $_ }, { $_.PSIsContainer } -Descending | Select-Object -First 1
if (-not $latest) { Stop-Update "No Iron-v* zip or folder found in $versions" }
$ver = VersionOf $latest

$src = $latest.FullName
if (-not $latest.PSIsContainer) {
  $src = Join-Path $versions ("Iron-v{0}" -f $ver)
  Expand-Archive $latest.FullName -DestinationPath $src -Force
}
$index = Get-ChildItem $src -Recurse -Filter index.html | Sort-Object { $_.FullName.Length } | Select-Object -First 1
if (-not $index) { Stop-Update "No index.html inside $src - is it the right folder?" }
$src = $index.DirectoryName

Write-Host ""
Write-Host "Updating to v$ver from:" -ForegroundColor Cyan
Write-Host "  $src"

# 3. don't wipe work that hasn't been committed
Set-Location $repo
$dirty = git status --porcelain
if ($dirty) {
  Write-Host ""
  Write-Host "The repo has changes that aren't committed yet:" -ForegroundColor Yellow
  $dirty | Select-Object -First 15 | ForEach-Object { Write-Host "  $_" }
  $ans = Read-Host "Replace them anyway? (y/n)"
  if ($ans -ne 'y') { Stop-Update "Stopped - nothing was changed." }
}

Get-ChildItem -Force | Where-Object { $keep -notcontains $_.Name } | Remove-Item -Recurse -Force
Copy-Item "$src\*" . -Recurse -Force

# 4. stage and show what changed
git add --all 2>$null
Write-Host ""
Write-Host "Changes (A = added, M = modified, D = deleted, R = renamed):" -ForegroundColor Cyan
git status --short
Write-Host ""
Write-Host "If anything shows as D (deleted) that you didn't expect, stop and check. Otherwise:" -ForegroundColor Cyan
Write-Host "  git commit -m `"v$ver`""
Write-Host "  ipush"
