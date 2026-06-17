Set-StrictMode -Version 2.0
$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ConfigFile = Join-Path $ScriptDir "config.env"

function Load-EnvFile {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Config file not found: $Path"
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

Load-EnvFile -Path $ConfigFile

$api = $env:MANGO_API_URL.TrimEnd("/")
if (-not $api.EndsWith("/chat/completions")) {
    $api = "$api/chat/completions"
}

$body = @{
    model = $env:MANGO_MODEL
    messages = @(
        @{ role = "user"; content = "Return exactly: OK" }
    )
    max_tokens = 16
    temperature = 0
} | ConvertTo-Json -Depth 10

$headers = @{
    "Content-Type" = "application/json"
    "Authorization" = "Bearer $env:MANGO_KEY"
}

Write-Host "Testing NewAPI endpoint: $api" -ForegroundColor Cyan
$resp = Invoke-RestMethod -Method Post -Uri $api -Headers $headers -Body $body -TimeoutSec 120
$content = $resp.choices[0].message.content
Write-Host "Model response:" -ForegroundColor Green
Write-Host $content
