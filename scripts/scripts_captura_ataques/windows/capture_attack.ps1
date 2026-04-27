param(
    [Parameter(Mandatory = $true)]
    [string]$Attack,
    [int]$DurationSeconds = 45
)

. "$PSScriptRoot\\Common.ps1"

$attackKey = Resolve-AttackKey $Attack

function Get-CaptureModeForAttack {
    param([string]$AttackName)

    switch ($AttackName) {
        "syn" { return "red_publica" }
        "udp" { return "red_publica" }
        "http" { return "red_publica" }
        "sqli_dos" { return "red_privada" }
        default { throw "No se pudo resolver el modo de captura para: $AttackName" }
    }
}

function Get-CaptureLabelForAttack {
    param(
        [string]$AttackName,
        [int]$DurationValue
    )

    switch ($AttackName) {
        "syn" { return "syn_$($DurationValue)s" }
        "udp" { return "udp_$($DurationValue)s" }
        "http" { return "http_$($DurationValue)s" }
        "sqli_dos" { return "sqli_$($DurationValue)s" }
        default { return "$AttackName`_$($DurationValue)s" }
    }
}

$captureMode = Get-CaptureModeForAttack $attackKey
$captureLabel = Get-CaptureLabelForAttack $attackKey $DurationSeconds

try {
    try { & (Join-Path $PSScriptRoot "stop_attacks.ps1") *> $null } catch {}
    try { & (Join-Path $PSScriptRoot "stop_capture.ps1") *> $null } catch {}

    Write-Host "Iniciando captura de $attackKey durante $DurationSeconds segundos..."
    Write-Host "Modo de captura: $captureMode"

    & (Join-Path $PSScriptRoot "start_capture.ps1") -Mode $captureMode -Label $captureLabel
    & (Join-Path $PSScriptRoot "attack.ps1") -Attack $attackKey
    Start-Sleep -Seconds $DurationSeconds
    & (Join-Path $PSScriptRoot "stop_attacks.ps1")
    & (Join-Path $PSScriptRoot "stop_capture.ps1")

    Write-Host ""
    Write-Host "Captura finalizada para $attackKey."
} catch {
    try { & (Join-Path $PSScriptRoot "stop_attacks.ps1") *> $null } catch {}
    try { & (Join-Path $PSScriptRoot "stop_capture.ps1") *> $null } catch {}
    throw
}
