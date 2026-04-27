param(
    [string]$Service,
    [switch]$Follow
)

. "$PSScriptRoot\\Common.ps1"

$args = @("logs")
if ($Follow) {
    $args += "-f"
}
if ($Service) {
    $args += $Service
}

Invoke-LabCompose @args
