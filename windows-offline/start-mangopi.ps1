Set-StrictMode -Version 2.0
$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = Split-Path -Parent $ScriptDir
$ConfigFile = Join-Path $ScriptDir "config.env"
$ExampleFile = Join-Path $ScriptDir "config.env.example"

function Load-EnvFile {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Config file not found: $Path. Copy config.env.example to config.env and edit it."
    }
    foreach ($line in Get-Content -LiteralPath $Path -Encoding UTF8) {
        $trimmed = $line.Trim()
        if (-not $trimmed -or $trimmed.StartsWith("#")) {
            continue
        }
        $idx = $trimmed.IndexOf("=")
        if ($idx -lt 1) {
            continue
        }
        $name = $trimmed.Substring(0, $idx).Trim()
        $value = $trimmed.Substring($idx + 1).Trim().Trim('"').Trim("'")
        [Environment]::SetEnvironmentVariable($name, $value, "Process")
    }
}

if (-not (Test-Path -LiteralPath $ConfigFile)) {
    if (Test-Path -LiteralPath $ExampleFile) {
        Copy-Item -LiteralPath $ExampleFile -Destination $ConfigFile
    }
    Write-Host "Created config.env from template. Edit it, then run start-mangopi.ps1 again." -ForegroundColor Yellow
    exit 1
}

Load-EnvFile -Path $ConfigFile

if (-not $env:MANGO_API_URL -or -not $env:MANGO_MODEL -or -not $env:MANGO_KEY) {
    throw "MANGO_API_URL, MANGO_MODEL and MANGO_KEY must be set in config.env."
}

$Python = Get-Command python -ErrorAction SilentlyContinue
if (-not $Python) {
    $Python = Get-Command py -ErrorAction SilentlyContinue
}
if (-not $Python) {
    throw "Python was not found. Install Python 3.8+ on this Windows host."
}

Write-Host "Mangopi CLI offline profile" -ForegroundColor Cyan
Write-Host "  API:   $env:MANGO_API_URL"
Write-Host "  Model: $env:MANGO_MODEL"
Write-Host "  Ctx:   $env:MANGO_MAX_CONTEXT"
Write-Host ""

& $Python.Source (Join-Path $RootDir "mangopi_cli.py")
