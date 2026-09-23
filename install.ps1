[CmdletBinding()]
param(
    [ValidateSet('all', 'claude', 'codex')]
    [string]$Target = 'all',
    [switch]$LegacyClaudeCommands,
    [switch]$MigrateLegacy,
    [switch]$Force,
    [string]$ClaudeRoot = $(if ($env:CLAUDE_CONFIG_DIR) { $env:CLAUDE_CONFIG_DIR } else { Join-Path ([Environment]::GetFolderPath('UserProfile')) '.claude' }),
    [string]$CodexRoot = $(if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path ([Environment]::GetFolderPath('UserProfile')) '.codex' })
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$skillSource = Join-Path $PSScriptRoot 'skills'
$legacyCommandSource = Join-Path $PSScriptRoot 'legacy/claude-commands'
$versionFile = Join-Path $PSScriptRoot 'VERSION'

if (-not (Test-Path -LiteralPath $skillSource -PathType Container)) {
    throw "Skill directory not found: $skillSource"
}
if (-not (Test-Path -LiteralPath $versionFile -PathType Leaf)) {
    throw "VERSION file not found: $versionFile"
}
if ($LegacyClaudeCommands -and $MigrateLegacy) {
    throw '-LegacyClaudeCommands and -MigrateLegacy cannot be used together.'
}

$packageVersion = (Get-Content -Raw -LiteralPath $versionFile).Trim()
$runTimestamp = (Get-Date).ToUniversalTime().ToString('yyyyMMdd-HHmmss')

function Get-FileSha256 {
    param([Parameter(Mandatory)] [string]$Path)
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Get-RelativeUnixPath {
    param(
        [Parameter(Mandatory)] [string]$Base,
        [Parameter(Mandatory)] [string]$Path
    )
    $basePath = [IO.Path]::GetFullPath($Base).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
    $fullPath = [IO.Path]::GetFullPath($Path)
    $prefix = $basePath + [IO.Path]::DirectorySeparatorChar
    if (-not $fullPath.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Path is outside the requested base: $fullPath"
    }
    return ($fullPath.Substring($prefix.Length) -replace '\\', '/')
}

function Get-DirectoryFileMap {
    param(
        [Parameter(Mandatory)] [string]$Root,
        [string]$Prefix = ''
    )

    $map = [ordered]@{}
    if (-not (Test-Path -LiteralPath $Root -PathType Container)) {
        return $map
    }
    Get-ChildItem -LiteralPath $Root -File -Recurse -Force | Sort-Object FullName | ForEach-Object {
        $relative = Get-RelativeUnixPath -Base $Root -Path $_.FullName
        $key = if ($Prefix) { "$($Prefix.TrimEnd('/'))/$relative" } else { $relative }
        $map[$key] = Get-FileSha256 -Path $_.FullName
    }
    return $map
}

function Get-PathFingerprint {
    param([Parameter(Mandatory)] [string]$Path)

    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        return Get-FileSha256 -Path $Path
    }
    $lines = [Collections.Generic.List[string]]::new()
    Get-ChildItem -LiteralPath $Path -File -Recurse -Force | Sort-Object FullName | ForEach-Object {
        $relative = Get-RelativeUnixPath -Base $Path -Path $_.FullName
        $lines.Add("$relative`t$(Get-FileSha256 -Path $_.FullName)")
    }
    [string[]]$sortedLines = @($lines)
    [Array]::Sort($sortedLines, [StringComparer]::Ordinal)
    $canonical = if ($sortedLines.Count -gt 0) { ($sortedLines -join "`n") + "`n" } else { '' }
    $bytes = [Text.Encoding]::UTF8.GetBytes($canonical)
    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        return ([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-', '').ToLowerInvariant()
    } finally {
        $sha.Dispose()
    }
}

function Assert-SafeChildPath {
    param(
        [Parameter(Mandatory)] [string]$Root,
        [Parameter(Mandatory)] [string]$Path
    )

    $fullRoot = [IO.Path]::GetFullPath($Root).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
    $fullPath = [IO.Path]::GetFullPath($Path)
    $prefix = $fullRoot + [IO.Path]::DirectorySeparatorChar
    if (-not $fullPath.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Unsafe path outside root: $fullPath"
    }
}

function Assert-SafeAgentRoot {
    param([Parameter(Mandatory)] [string]$Root)

    $fullRoot = [IO.Path]::GetFullPath($Root).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
    $volumeRoot = [IO.Path]::GetPathRoot($fullRoot).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
    if ($fullRoot -eq $volumeRoot) {
        throw "Agent root must not be a filesystem root: $fullRoot"
    }
}

function Test-DirectoryEqual {
    param(
        [Parameter(Mandatory)] [string]$Left,
        [Parameter(Mandatory)] [string]$Right
    )

    if (-not (Test-Path -LiteralPath $Left -PathType Container) -or
        -not (Test-Path -LiteralPath $Right -PathType Container)) {
        return $false
    }
    $leftMap = Get-DirectoryFileMap -Root $Left
    $rightMap = Get-DirectoryFileMap -Root $Right
    if ($leftMap.Count -ne $rightMap.Count) {
        return $false
    }
    foreach ($key in $leftMap.Keys) {
        if (-not $rightMap.Contains($key) -or $leftMap[$key] -ne $rightMap[$key]) {
            return $false
        }
    }
    return $true
}

function Read-InstallManifest {
    param([Parameter(Mandatory)] [string]$AgentRoot)

    $path = Join-Path $AgentRoot 'coding-agent-workflows/install-manifest.json'
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        return $null
    }
    try {
        return Get-Content -Raw -LiteralPath $path | ConvertFrom-Json
    } catch {
        Write-Warning "Ignoring unreadable install manifest: $path"
        return $null
    }
}

function Get-ManifestFileMap {
    param($Manifest)

    $map = [ordered]@{}
    if ($null -eq $Manifest -or $null -eq $Manifest.files) {
        return $map
    }
    foreach ($property in $Manifest.files.PSObject.Properties) {
        $map[$property.Name] = [string]$property.Value
    }
    return $map
}

function Test-ManagedDirectoryUnchanged {
    param(
        [Parameter(Mandatory)] [string]$AgentRoot,
        [Parameter(Mandatory)] [string]$SkillName,
        $Manifest
    )

    $expected = Get-ManifestFileMap -Manifest $Manifest
    $prefix = "skills/$SkillName/"
    $expectedSubset = [ordered]@{}
    foreach ($key in $expected.Keys) {
        if ($key.StartsWith($prefix, [StringComparison]::Ordinal)) {
            $expectedSubset[$key] = $expected[$key]
        }
    }
    if ($expectedSubset.Count -eq 0) {
        return $false
    }

    $destination = Join-Path (Join-Path $AgentRoot 'skills') $SkillName
    $actual = Get-DirectoryFileMap -Root $destination -Prefix "skills/$SkillName"
    if ($actual.Count -ne $expectedSubset.Count) {
        return $false
    }
    foreach ($key in $actual.Keys) {
        if (-not $expectedSubset.Contains($key) -or $actual[$key] -ne $expectedSubset[$key]) {
            return $false
        }
    }
    return $true
}

function Get-LegacyCandidates {
    param(
        [Parameter(Mandatory)] [string]$AgentRoot,
        [Parameter(Mandatory)] [ValidateSet('claude', 'codex')] [string]$Agent,
        $Manifest
    )

    $items = [Collections.Generic.List[object]]::new()
    $skillMappings = [ordered]@{
        'review' = 'pr-review'
        'pr-review' = 'pr-review'
        'pr-re-review' = 'pr-review'
        'review-followup' = 'pr-followup'
        'pr-merge' = 'pr-merge'
        'startup-status' = 'startup-status'
    }
    foreach ($oldName in $skillMappings.Keys) {
        $path = Join-Path (Join-Path $AgentRoot 'skills') $oldName
        if (-not (Test-Path -LiteralPath $path -PathType Container)) {
            continue
        }
        $currentSource = Join-Path $skillSource $oldName
        if (Test-Path -LiteralPath $currentSource -PathType Container) {
            if (Test-DirectoryEqual -Left $currentSource -Right $path) {
                continue
            }
            $managedFiles = Get-ManifestFileMap -Manifest $Manifest
            $managedPrefix = "skills/$oldName/"
            if (@($managedFiles.Keys | Where-Object { $_.StartsWith($managedPrefix, [StringComparison]::Ordinal) }).Count -gt 0) {
                continue
            }
        }
        $items.Add([pscustomobject]@{
            Path = $path
            Relative = "skills/$oldName"
            Mapping = $skillMappings[$oldName]
        })
    }

    if ($Agent -eq 'claude') {
        $commandMappings = [ordered]@{
            'review.md' = 'pr-review'
            'pr_review.md' = 'pr-review'
            'pr_re_review.md' = 'pr-review'
            'review_followup.md' = 'pr-followup'
            'pr_merge.md' = 'pr-merge'
            'startup_status.md' = 'startup-status'
        }
        foreach ($fileName in $commandMappings.Keys) {
            $path = Join-Path (Join-Path $AgentRoot 'commands') $fileName
            if (Test-Path -LiteralPath $path -PathType Leaf) {
                $items.Add([pscustomobject]@{
                    Path = $path
                    Relative = "commands/$fileName"
                    Mapping = $commandMappings[$fileName]
                })
            }
        }
    }
    return $items
}

function Inspect-Or-MigrateLegacy {
    param(
        [Parameter(Mandatory)] [string]$AgentRoot,
        [Parameter(Mandatory)] [ValidateSet('claude', 'codex')] [string]$Agent,
        $Manifest
    )

    $records = [Collections.Generic.List[object]]::new()
    $candidates = @(Get-LegacyCandidates -AgentRoot $AgentRoot -Agent $Agent -Manifest $Manifest)
    foreach ($candidate in $candidates) {
        $hash = Get-PathFingerprint -Path $candidate.Path
        Write-Warning "Legacy $Agent item: $($candidate.Path) [sha256:$hash] -> $($candidate.Mapping)"
        if (-not $MigrateLegacy) {
            continue
        }

        $backupRoot = Join-Path $AgentRoot "coding-agent-workflows/backups/$runTimestamp"
        $backupPath = Join-Path $backupRoot ($candidate.Relative -replace '/', [IO.Path]::DirectorySeparatorChar)
        Assert-SafeChildPath -Root $AgentRoot -Path $candidate.Path
        Assert-SafeChildPath -Root $AgentRoot -Path $backupPath
        New-Item -ItemType Directory -Path (Split-Path -Parent $backupPath) -Force | Out-Null
        Move-Item -LiteralPath $candidate.Path -Destination $backupPath
        Write-Host "Backed up legacy $Agent item: $($candidate.Path) -> $backupPath"
        $records.Add([ordered]@{
            source = $candidate.Path
            backup = $backupPath
            sha256 = $hash
            replacement = $candidate.Mapping
        })
    }
    if ($candidates.Count -gt 0 -and -not $MigrateLegacy) {
        Write-Warning 'Legacy items were not changed. Re-run with -MigrateLegacy to back them up and remove the originals.'
    }
    return $records
}

function Replace-SkillDirectory {
    param(
        [Parameter(Mandatory)] [string]$Source,
        [Parameter(Mandatory)] [string]$Destination,
        [Parameter(Mandatory)] [string]$AgentRoot
    )

    Assert-SafeChildPath -Root $AgentRoot -Path $Destination
    if (Test-Path -LiteralPath $Destination) {
        Remove-Item -LiteralPath $Destination -Recurse -Force
    }
    Copy-Item -LiteralPath $Source -Destination $Destination -Recurse
}

function Write-InstallManifest {
    param(
        [Parameter(Mandatory)] [string]$AgentRoot,
        [Parameter(Mandatory)] [AllowEmptyCollection()] [object[]]$Migrations
    )

    $existing = Read-InstallManifest -AgentRoot $AgentRoot
    $existingFiles = Get-ManifestFileMap -Manifest $existing
    $files = [ordered]@{}
    foreach ($sourceDirectory in Get-ChildItem -LiteralPath $skillSource -Directory | Sort-Object Name) {
        $destination = Join-Path (Join-Path $AgentRoot 'skills') $sourceDirectory.Name
        if (Test-DirectoryEqual -Left $sourceDirectory.FullName -Right $destination) {
            $fileMap = Get-DirectoryFileMap -Root $destination -Prefix "skills/$($sourceDirectory.Name)"
            foreach ($key in $fileMap.Keys) {
                $files[$key] = $fileMap[$key]
            }
        } else {
            $prefix = "skills/$($sourceDirectory.Name)/"
            foreach ($key in $existingFiles.Keys) {
                if ($key.StartsWith($prefix, [StringComparison]::Ordinal)) {
                    $files[$key] = $existingFiles[$key]
                }
            }
        }
    }

    $migrationHistory = [Collections.Generic.List[object]]::new()
    if ($null -ne $existing -and $null -ne $existing.migrations) {
        foreach ($record in @($existing.migrations)) {
            $migrationHistory.Add($record)
        }
    }
    foreach ($record in $Migrations) {
        $migrationHistory.Add($record)
    }

    $manifest = [ordered]@{
        schemaVersion = 1
        packageVersion = $packageVersion
        installedAt = (Get-Date).ToUniversalTime().ToString('o')
        files = $files
        migrations = @($migrationHistory)
    }
    $manifestDirectory = Join-Path $AgentRoot 'coding-agent-workflows'
    New-Item -ItemType Directory -Path $manifestDirectory -Force | Out-Null
    $manifestPath = Join-Path $manifestDirectory 'install-manifest.json'
    $manifest | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $manifestPath -Encoding utf8
    Write-Host "Wrote install manifest: $manifestPath"
}

function Install-Skills {
    param(
        [Parameter(Mandatory)] [string]$AgentRoot,
        [Parameter(Mandatory)] [ValidateSet('claude', 'codex')] [string]$Agent
    )

    Assert-SafeAgentRoot -Root $AgentRoot
    $manifest = Read-InstallManifest -AgentRoot $AgentRoot
    $legacyCandidates = @(Get-LegacyCandidates -AgentRoot $AgentRoot -Agent $Agent -Manifest $manifest)
    $migrations = @(Inspect-Or-MigrateLegacy -AgentRoot $AgentRoot -Agent $Agent -Manifest $manifest)
    $destinationRoot = Join-Path $AgentRoot 'skills'
    New-Item -ItemType Directory -Path $destinationRoot -Force | Out-Null

    foreach ($sourceDirectory in Get-ChildItem -LiteralPath $skillSource -Directory | Sort-Object Name) {
        $destination = Join-Path $destinationRoot $sourceDirectory.Name
        if (Test-DirectoryEqual -Left $sourceDirectory.FullName -Right $destination) {
            Write-Host "Already current $Agent skill: $destination"
            continue
        }
        $isUnmigratedLegacy = -not $MigrateLegacy -and @($legacyCandidates | Where-Object { $_.Path -eq $destination }).Count -gt 0
        if ((Test-Path -LiteralPath $destination) -and $isUnmigratedLegacy) {
            Write-Warning "Skipped legacy $Agent skill: $destination (use -MigrateLegacy to back it up first; -Force does not bypass migration)"
            continue
        }
        if (Test-Path -LiteralPath $destination) {
            $managedUnchanged = Test-ManagedDirectoryUnchanged -AgentRoot $AgentRoot -SkillName $sourceDirectory.Name -Manifest $manifest
            if (-not $Force -and -not $managedUnchanged) {
                Write-Warning "Skipped unmanaged or modified $Agent skill: $destination (use -Force after review)"
                continue
            }
        }
        Replace-SkillDirectory -Source $sourceDirectory.FullName -Destination $destination -AgentRoot $AgentRoot
        Write-Host "Installed $Agent skill: $destination"
    }
    Write-InstallManifest -AgentRoot $AgentRoot -Migrations $migrations
}

function Install-LegacyCommands {
    param([Parameter(Mandatory)] [string]$AgentRoot)

    Assert-SafeAgentRoot -Root $AgentRoot
    if (-not (Test-Path -LiteralPath $legacyCommandSource -PathType Container)) {
        throw "Legacy command directory not found: $legacyCommandSource"
    }
    foreach ($sourceDirectory in Get-ChildItem -LiteralPath $skillSource -Directory) {
        $newSkill = Join-Path (Join-Path $AgentRoot 'skills') $sourceDirectory.Name
        if (Test-Path -LiteralPath $newSkill) {
            throw "Legacy commands cannot be installed alongside new workflow skills: $newSkill"
        }
    }

    Write-Warning '-LegacyClaudeCommands is deprecated. No new Claude Code workflow Skills will be installed in this mode.'
    $destinationRoot = Join-Path $AgentRoot 'commands'
    New-Item -ItemType Directory -Path $destinationRoot -Force | Out-Null
    Get-ChildItem -LiteralPath $legacyCommandSource -Filter '*.md' -File | Sort-Object Name | ForEach-Object {
        $destination = Join-Path $destinationRoot $_.Name
        if ((Test-Path -LiteralPath $destination) -and -not $Force) {
            Write-Warning "Skipped existing legacy Claude Code command: $destination"
            return
        }
        Copy-Item -LiteralPath $_.FullName -Destination $destination -Force:$Force
        Write-Host "Installed legacy Claude Code command: $destination"
    }
}

if ($Target -in @('all', 'claude')) {
    if ($LegacyClaudeCommands) {
        Install-LegacyCommands -AgentRoot $ClaudeRoot
    } else {
        Install-Skills -AgentRoot $ClaudeRoot -Agent claude
    }
}

if ($Target -in @('all', 'codex')) {
    Install-Skills -AgentRoot $CodexRoot -Agent codex
}

Write-Host "Installation complete (package $packageVersion). Start a new agent session before using newly installed skills."
