. "$PSScriptRoot\\Common.ps1"

Write-Host "Levantando el laboratorio y el stack de monitoreo..."
Invoke-LabCompose up -d --build

Write-Host ""
Write-Host "Servicios principales:"
Invoke-LabCompose ps

Write-Host ""
Write-Host "URLs:"
Write-Host "  EmpresaX: $Script:WebUrl"
Write-Host "  Panel DDoS: $Script:PanelUrl"
Write-Host "  Grafana: $Script:GrafanaUrl"
Write-Host "  Prometheus: $Script:PromUrl"
Write-Host "  Loki ready: $Script:LokiUrl/ready"
