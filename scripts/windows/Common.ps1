Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$Script:RootDir = (Resolve-Path (Join-Path $PSScriptRoot "..\\..")).Path
$Script:ComposeFile = Join-Path $Script:RootDir "infra/docker-compose.yml"
$Script:PanelUrl = "http://localhost:5000"
$Script:WebUrl = "http://localhost:8080"
$Script:PromUrl = "http://localhost:9090"
$Script:GrafanaUrl = "http://localhost:3000"
$Script:LokiUrl = "http://localhost:3100"

function Invoke-LabCompose {
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Args
    )

    & docker compose -f $Script:ComposeFile @Args
}

function Get-HttpCode {
    param([Parameter(Mandatory = $true)][string]$Url)
    (& curl.exe -s -o NUL -w "%{http_code}" $Url).Trim()
}

function Resolve-AttackKey {
    param([Parameter(Mandatory = $true)][string]$Attack)

    switch ($Attack.ToLowerInvariant()) {
        "udp" { return "udp" }
        "udp_flood" { return "udp" }
        "syn" { return "syn" }
        "syn_flood" { return "syn" }
        "ack" { return "ack" }
        "ack_flood" { return "ack" }
        "conntrack" { return "conntrack" }
        "conntrack_killer" { return "conntrack" }
        "http" { return "http" }
        "http_flood" { return "http" }
        "sqli" { return "sqli_dos" }
        "sqli_dos" { return "sqli_dos" }
        "sqlidos" { return "sqli_dos" }
        default {
            throw "Ataque no reconocido: $Attack. Opciones: udp, syn, ack, conntrack, http, sqli_dos"
        }
    }
}

function Invoke-LabAttack {
    param([Parameter(Mandatory = $true)][string]$Attack)
    & curl.exe --fail --silent --show-error "$Script:PanelUrl/atacar/$Attack"
}

function Get-ContainerState {
    param([Parameter(Mandatory = $true)][string]$Name)

    $status = (& docker inspect -f "{{.State.Status}}" $Name 2>$null).Trim()
    $health = (& docker inspect -f "{{if .State.Health}}{{.State.Health.Status}}{{end}}" $Name 2>$null).Trim()
    [pscustomobject]@{
        Status = $status
        Health = $health
    }
}
