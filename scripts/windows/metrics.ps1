. "$PSScriptRoot\\Common.ps1"

$targets = (& curl.exe -s "$Script:PromUrl/api/v1/targets") | ConvertFrom-Json
$labUp = (& curl.exe -s --get --data-urlencode "query=lab_container_up" "$Script:PromUrl/api/v1/query") | ConvertFrom-Json
$attacks = (& curl.exe -s --get --data-urlencode "query=attack_active" "$Script:PromUrl/api/v1/query") | ConvertFrom-Json

Write-Host "Targets de Prometheus:"
$targets.data.activeTargets |
    Select-Object @{Name = "job"; Expression = { $_.labels.job } }, health, lastError |
    Format-Table -AutoSize

Write-Host ""
Write-Host "Disponibilidad de contenedores:"
$labUp.data.result |
    Select-Object @{Name = "container"; Expression = { $_.metric.container } }, @{Name = "value"; Expression = { $_.value[1] } } |
    Format-Table -AutoSize

Write-Host ""
Write-Host "Ataques marcados como activos:"
$attacks.data.result |
    Select-Object @{Name = "attack"; Expression = { $_.metric.attack } }, @{Name = "value"; Expression = { $_.value[1] } } |
    Format-Table -AutoSize
