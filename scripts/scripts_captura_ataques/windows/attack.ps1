param(
    [Parameter(Mandatory = $true)]
    [string]$Attack
)

. "$PSScriptRoot\\Common.ps1"

$attackKey = Resolve-AttackKey $Attack
Invoke-LabAttack $attackKey
Write-Host ""
Write-Host "Ataque lanzado: $attackKey"
