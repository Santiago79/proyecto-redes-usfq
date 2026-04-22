. "$PSScriptRoot\\Common.ps1"

Write-Host "Reinicializando el laboratorio (down -v y nuevo up -d --build)..."
Invoke-LabCompose down -v --remove-orphans
Invoke-LabCompose up -d --build

Write-Host ""
Write-Host "Laboratorio reiniciado."
