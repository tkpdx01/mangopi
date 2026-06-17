Set-StrictMode -Version 2.0
$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot
$Version = "0.1.27"
$OutDir = Join-Path $RepoRoot "dist"
$PkgName = "mangopi-cli-windows-offline-$Version"
$Stage = Join-Path $OutDir $PkgName
$ZipPath = Join-Path $OutDir "$PkgName.zip"

if (Test-Path -LiteralPath $Stage) {
    Remove-Item -LiteralPath $Stage -Recurse -Force
}
New-Item -ItemType Directory -Path $Stage | Out-Null

$items = @(
    "mangopi_cli.py",
    "README.md",
    "LICENSE",
    "pyproject.toml",
    "windows-offline",
    "docs"
)

foreach ($item in $items) {
    $src = Join-Path $RepoRoot $item
    if (-not (Test-Path -LiteralPath $src)) {
        continue
    }
    $dst = Join-Path $Stage $item
    if ((Get-Item -LiteralPath $src).PSIsContainer) {
        Copy-Item -LiteralPath $src -Destination $dst -Recurse
    } else {
        Copy-Item -LiteralPath $src -Destination $dst
    }
}

if (Test-Path -LiteralPath $ZipPath) {
    Remove-Item -LiteralPath $ZipPath -Force
}
Compress-Archive -Path (Join-Path $Stage "*") -DestinationPath $ZipPath -Force

Write-Host "Created: $ZipPath" -ForegroundColor Green
