[CmdletBinding()]
param(
    [string]$Destination = (Join-Path $HOME '.claude\commands'),
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$source = Join-Path $PSScriptRoot 'commands'
if (-not (Test-Path -LiteralPath $source -PathType Container)) {
    throw "Command directory not found: $source"
}

New-Item -ItemType Directory -Path $Destination -Force | Out-Null

$installed = 0
$skipped = 0

Get-ChildItem -LiteralPath $source -Filter '*.md' -File | Sort-Object Name | ForEach-Object {
    $target = Join-Path $Destination $_.Name
    if ((Test-Path -LiteralPath $target) -and -not $Force) {
        Write-Warning "Skipped existing command: $target"
        $skipped++
        return
    }

    Copy-Item -LiteralPath $_.FullName -Destination $target -Force:$Force
    Write-Host "Installed: $target"
    $installed++
}

Write-Host "Completed. Installed: $installed; skipped: $skipped"

