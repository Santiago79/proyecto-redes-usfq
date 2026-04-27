. "$PSScriptRoot\\Common.ps1"

$captureContainer = "router"
$captureState = Get-ContainerState $captureContainer
if ($captureState.Status -ne "running") {
    throw "El contenedor $captureContainer no esta corriendo."
}

& docker exec $captureContainer sh /opt/lab_scripts/monitor/stop_capture.sh
if ($LASTEXITCODE -ne 0) {
    throw "No se pudo detener la captura."
}

Write-Host ""
Write-Host "Archivos de captura en: $(Join-Path $Script:RootDir 'analisis\\pcaps')"
