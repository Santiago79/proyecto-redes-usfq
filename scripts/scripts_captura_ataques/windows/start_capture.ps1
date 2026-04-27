param(
    [string]$Mode = "todas",
    [string]$Label = "captura",
    [int]$RingSizeMB = 25,
    [int]$RingFiles = 5
)

. "$PSScriptRoot\\Common.ps1"

$captureDir = Join-Path $Script:RootDir "analisis\\pcaps"
$captureContainer = "router"
New-Item -ItemType Directory -Force -Path $captureDir | Out-Null

$monitorState = Get-ContainerState "monitor"
if ($monitorState.Status -ne "running") {
    throw "El contenedor monitor no esta corriendo. Levanta primero el laboratorio."
}

$captureState = Get-ContainerState $captureContainer
if ($captureState.Status -ne "running") {
    throw "El contenedor $captureContainer no esta corriendo. Levanta primero el laboratorio."
}

& docker exec `
    -e "CAPTURE_NODE=$captureContainer" `
    -e "CAPTURE_PUBLIC_IP=172.20.10.254" `
    -e "CAPTURE_PRIVATE_IP=172.20.20.254" `
    -e "CAPTURE_ATTACK_IP=172.20.30.254" `
    $captureContainer `
    sh /opt/lab_scripts/monitor/start_capture.sh $Mode $Label $RingSizeMB $RingFiles
if ($LASTEXITCODE -ne 0) {
    throw "No se pudo iniciar la captura."
}

Write-Host ""
Write-Host "Archivos de captura en: $captureDir"
