param(
    [int]$DurationSeconds = 45
)

. "$PSScriptRoot\\Common.ps1"

function Get-LabelPrefixForAttack {
    param(
        [string]$AttackName,
        [int]$DurationValue
    )

    switch ($AttackName) {
        "syn" { return "syn_$($DurationValue)s_red_publica" }
        "udp" { return "udp_$($DurationValue)s_red_publica" }
        "http" { return "http_$($DurationValue)s_red_publica" }
        "sqli_dos" { return "sqli_$($DurationValue)s_red_privada" }
        default { return "$AttackName`_$($DurationValue)s" }
    }
}

$summaryFile = Join-Path $Script:RootDir "analisis\\pcaps\\capturas_45s_resumen.txt"
New-Item -ItemType Directory -Force -Path (Split-Path $summaryFile -Parent) | Out-Null

@(
    "Resumen de capturas de 45 segundos"
    "Fecha UTC: $([DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ'))"
    "Duracion por ataque: $DurationSeconds segundos"
    ""
) | Set-Content -Path $summaryFile -Encoding UTF8

foreach ($attack in @("syn", "udp", "http", "sqli_dos")) {
    Write-Host "=============================="
    Write-Host "Capturando ataque: $attack"
    & (Join-Path $PSScriptRoot "capture_attack.ps1") -Attack $attack -DurationSeconds $DurationSeconds
    Add-Content -Path $summaryFile -Value "- $attack completado"
    $prefix = Get-LabelPrefixForAttack $attack $DurationSeconds
    Get-ChildItem (Join-Path $Script:RootDir "analisis\\pcaps") |
        Where-Object { -not $_.PSIsContainer -and (($_.Name -like "$prefix*.pcap*") -or ($_.Name -like "$prefix*.pcapng*")) } |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 10 -ExpandProperty Name |
        Add-Content -Path $summaryFile
    Add-Content -Path $summaryFile -Value ""
    Start-Sleep -Seconds 3
}

Write-Host "Resumen guardado en: $summaryFile"
