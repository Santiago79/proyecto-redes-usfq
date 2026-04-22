. "$PSScriptRoot\\Common.ps1"

$failures = 0

function Assert-Step {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][scriptblock]$Check
    )

    try {
        if (& $Check) {
            Write-Host "[OK] $Name"
        } else {
            Write-Host "[FAIL] $Name" -ForegroundColor Red
            $script:failures++
        }
    } catch {
        Write-Host "[FAIL] $Name -> $($_.Exception.Message)" -ForegroundColor Red
        $script:failures++
    }
}

function Targets-Up {
    $response = (& curl.exe -s "$Script:PromUrl/api/v1/targets") | ConvertFrom-Json
    $jobs = "apache_exporter", "blackbox_http", "blackbox_tcp", "cadvisor", "docker_metrics_exporter", "mysqld_exporter", "panel_control", "prometheus"
    foreach ($job in $jobs) {
        $matches = $response.data.activeTargets | Where-Object { $_.labels.job -eq $job -and $_.health -eq "up" }
        if (-not $matches) {
            return $false
        }
    }
    return $true
}

function Dashboards-Ready {
    $response = (& curl.exe -s -u "admin:admin" "$Script:GrafanaUrl/api/search?query=") | ConvertFrom-Json
    $titles = "Infraestructura General", "Servidor Web", "Base de Datos", "Red y Ataques", "Academico Explicativo", "Logs del Laboratorio"
    foreach ($title in $titles) {
        if (-not ($response | Where-Object { $_.title -eq $title })) {
            return $false
        }
    }
    return $true
}

function Lab-Metrics-Ready {
    $response = (& curl.exe -s --get --data-urlencode "query=lab_container_up" "$Script:PromUrl/api/v1/query") | ConvertFrom-Json
    $containers = $response.data.result.metric.container
    return ($containers -contains "servidor_web") -and ($containers -contains "base_datos") -and ($containers -contains "atacante")
}

Assert-Step "router activo" { (Get-ContainerState "router").Status -eq "running" }
Assert-Step "servidor_web saludable" { (Get-ContainerState "servidor_web").Health -eq "healthy" }
Assert-Step "base_datos saludable" { (Get-ContainerState "base_datos").Health -eq "healthy" }
Assert-Step "atacante saludable" { (Get-ContainerState "atacante").Health -eq "healthy" }
Assert-Step "panel_control saludable" { (Get-ContainerState "panel_control").Health -eq "healthy" }
Assert-Step "prometheus activo" { (Get-ContainerState "prometheus").Status -eq "running" }
Assert-Step "grafana activo" { (Get-ContainerState "grafana").Status -eq "running" }
Assert-Step "loki activo" { (Get-ContainerState "loki").Status -eq "running" }
Assert-Step "tcp_syncookies desactivado" { (& docker exec servidor_web cat /proc/sys/net/ipv4/tcp_syncookies).Trim() -eq "0" }
Assert-Step "EmpresaX responde 200" { (Get-HttpCode $Script:WebUrl) -eq "200" }
Assert-Step "Panel responde 200" { (Get-HttpCode $Script:PanelUrl) -eq "200" }
Assert-Step "Grafana responde 200 o 302" { (Get-HttpCode $Script:GrafanaUrl) -in @("200", "302") }
Assert-Step "Loki ready" { ((& curl.exe -s "$Script:LokiUrl/ready").Trim()) -eq "ready" }
Assert-Step "Prometheus scrapea targets reales" { Targets-Up }
Assert-Step "Grafana provisiono dashboards" { Dashboards-Ready }
Assert-Step "Prometheus expone metricas del laboratorio" { Lab-Metrics-Ready }

if ($failures -gt 0) {
    throw "La validacion detecto $failures fallo(s)."
}

Write-Host ""
Write-Host "Validacion completada sin fallos."
