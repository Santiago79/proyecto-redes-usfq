param(
    [int]$DurationSeconds = 60,
    [int]$IntervalMilliseconds = 1000,
    [string]$OutputFile = ""
)

. "$PSScriptRoot\\Common.ps1"

if (-not $OutputFile) {
    $OutputFile = Join-Path $Script:RootDir "analisis\\trafico_legitimo_windows.csv"
}

$outputDir = Split-Path -Parent $OutputFile
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
}

"timestamp,http_code,latency_seconds" | Set-Content -Path $OutputFile
$endAt = (Get-Date).AddSeconds($DurationSeconds)

while ((Get-Date) -lt $endAt) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $response = (& curl.exe -s -o NUL -w "%{http_code},%{time_total}" $Script:WebUrl).Trim()
    "$timestamp,$response" | Tee-Object -FilePath $OutputFile -Append
    Start-Sleep -Milliseconds $IntervalMilliseconds
}

Write-Host ""
Write-Host "Trafico legitimo registrado en: $OutputFile"
