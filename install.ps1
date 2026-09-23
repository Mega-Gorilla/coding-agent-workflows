[CmdletBinding()]
param(
    [ValidateSet('all', 'claude', 'codex')]
    [string]$Target = 'all',
    [switch]$LegacyClaudeCommands,
    [switch]$Force,
    [string]$ClaudeRoot = $(if ($env:CLAUDE_CONFIG_DIR) { $env:CLAUDE_CONFIG_DIR } else { Join-Path $HOME '.claude' }),
    [string]$CodexRoot = $(if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $HOME '.codex' })
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$skillSource = Join-Path $PSScriptRoot 'skills'
$commandSource = Join-Path $PSScriptRoot 'commands'

if (-not (Test-Path -LiteralPath $skillSource -PathType Container)) {
    throw "Skill directory not found: $skillSource"
}

function Install-DirectoryContent {
    param(
        [Parameter(Mandatory)] [string]$Source,
        [Parameter(Mandatory)] [string]$Destination,
        [Parameter(Mandatory)] [string]$Label
    )

    New-Item -ItemType Directory -Path $Destination -Force | Out-Null

    Get-ChildItem -LiteralPath $Source -Directory | Sort-Object Name | ForEach-Object {
        $targetPath = Join-Path $Destination $_.Name
        if ((Test-Path -LiteralPath $targetPath) -and -not $Force) {
            Write-Warning "Skipped existing ${Label}: $targetPath"
            return
        }

        if (Test-Path -LiteralPath $targetPath) {
            Get-ChildItem -LiteralPath $_.FullName -Force | Copy-Item -Destination $targetPath -Recurse -Force
        } else {
            Copy-Item -LiteralPath $_.FullName -Destination $targetPath -Recurse
        }
        Write-Host "Installed ${Label}: $targetPath"
    }
}

if ($Target -in @('all', 'claude')) {
    Install-DirectoryContent -Source $skillSource -Destination (Join-Path $ClaudeRoot 'skills') -Label 'Claude Code skill'
}

if ($Target -in @('all', 'codex')) {
    Install-DirectoryContent -Source $skillSource -Destination (Join-Path $CodexRoot 'skills') -Label 'Codex skill'
}

if ($LegacyClaudeCommands) {
    if (-not (Test-Path -LiteralPath $commandSource -PathType Container)) {
        throw "Legacy command directory not found: $commandSource"
    }

    $commandDestination = Join-Path $ClaudeRoot 'commands'
    New-Item -ItemType Directory -Path $commandDestination -Force | Out-Null

    Get-ChildItem -LiteralPath $commandSource -Filter '*.md' -File | Sort-Object Name | ForEach-Object {
        $targetPath = Join-Path $commandDestination $_.Name
        if ((Test-Path -LiteralPath $targetPath) -and -not $Force) {
            Write-Warning "Skipped existing Claude Code command: $targetPath"
            return
        }

        Copy-Item -LiteralPath $_.FullName -Destination $targetPath -Force:$Force
        Write-Host "Installed Claude Code command: $targetPath"
    }
}

Write-Host 'Installation complete. Start a new agent session before using newly installed skills.'
