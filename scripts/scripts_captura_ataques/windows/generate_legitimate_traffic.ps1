param(
    [int]$IntervalMilliseconds = 500,
    [string]$OutputFile = "",
    [string]$TargetUrl = ""
)

. "$PSScriptRoot\\Common.ps1"

if (-not $OutputFile) {
    $OutputFile = Join-Path $Script:RootDir "analisis\\trafico_base.csv"
}

if (-not $TargetUrl) {
    $TargetUrl = $Script:WebUrl
}

$outputDir = Split-Path -Parent $OutputFile
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
}

"timestamp,http_code,latency_seconds" | Set-Content -Path $OutputFile

Write-Host "======================================================"
Write-Host " Iniciando sonda de trafico HTTP hacia $TargetUrl"
Write-Host " Guardando muestras en: $OutputFile"
Write-Host " Presiona Ctrl + C para detener la ejecucion."
Write-Host "======================================================"

try {
    while ($true) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $response = (& curl.exe -s -o NUL -w "%{http_code},%{time_total}" $TargetUrl).Trim()
        $parts = $response -split ",", 2
        $httpCode = $parts[0]
        $latency = if ($parts.Length -gt 1) { $parts[1] } else { "" }
        Write-Host "[$timestamp] Codigo HTTP: $httpCode | Latencia: $($latency)s"
        "$timestamp,$httpCode,$latency" | Add-Content -Path $OutputFile
        Start-Sleep -Milliseconds $IntervalMilliseconds
    }
} finally {
    Write-Host ""
    Write-Host "Trafico legitimo detenido. CSV disponible en: $OutputFile"
}
