<#
.SYNOPSIS
    Builds the user-facing release package: the product, not the repository.

.DESCRIPTION
    A release asset should contain what someone needs in order to run the tool,
    and nothing else. The source archives Gitea and GitHub generate already exist
    for anyone who wants the repository -- test suites, CI workflows, editor
    settings and all -- but somebody who downloads "WinCleanKit-0.1.0.zip" should
    not have to work out which of thirty files matter.

    Both lists below are closed. A file is in the package because it is named in
    the include list, and a development file is left out because it is named in
    the exclusion list. Anything that matches neither stops the build, so a new
    file cannot quietly ship to users or quietly fail to ship.

    The version is read from the engine, so the package name, the folder inside
    it and the version the tool reports cannot drift apart.

    Output, in dist/ by default:

        WinCleanKit-<version>.zip          top-level folder WinCleanKit-<version>
        WinCleanKit-<version>.zip.sha256   the hash, for verifying the download

.PARAMETER OutDir
    Where to write the package. Defaults to dist/ at the repository root.

.PARAMETER NoHash
    Skip the .sha256 sidecar. tests/Test-Release.ps1 checks the hash itself and
    does not need a second file to clean up.

.EXAMPLE
    .\tools\New-ReleasePackage.ps1
#>
[CmdletBinding()]
param(
    [string]$OutDir,
    [switch]$NoHash
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
if (-not $OutDir) { $OutDir = Join-Path $root 'dist' }

$enginePath = Join-Path $root 'src/WinCleanKit.ps1'
if (-not (Test-Path $enginePath)) { throw "engine not found: $enginePath" }
$engineText = Get-Content $enginePath -Raw -Encoding UTF8
$versionMatch = [regex]::Match($engineText, "EngineVersion\s*=\s*'([^']+)'")
if (-not $versionMatch.Success) { throw "could not read the engine version from $enginePath" }
$version = $versionMatch.Groups[1].Value

# ---------------------------------------------------------------------------
# What a user gets, and what they do not.
# ---------------------------------------------------------------------------
$IncludeFile = @(
    'run.bat'
    'LICENSE'
    'CHANGELOG.md'
    'release/README.md'
    'release/README.zh-CN.md'
)
$IncludeDir = @('src', 'catalog', 'docs')

# The front page of the download is not the project page: it has no badges, no CI
# status and no contributing section, and its links point only at files that ship.
# It is written in release/ as if it sat at the root, so packaging it means two
# mechanical steps, both verified by tests/Test-Release.ps1: it is renamed, and the
# leading "../" comes off its links. The rename is what makes the other documents'
# own "../README.md" links resolve inside the package.
$Rename = @{
    'release/README.md'        = 'README.md'
    'release/README.zh-CN.md'  = 'README.zh-CN.md'
}
$RewriteRootLinks = @('release/README.md', 'release/README.zh-CN.md')

# Development machinery: the tests that check the product, the tools that
# generate its documentation, the CI definitions, and editor configuration.
$ExcludeDir = @('tests', 'tools', 'localization', 'dist', '.git', '.github', '.gitea', '.vscode')
$ExcludeFile = @(
    '.gitignore'
    '.gitattributes'
    '.editorconfig'
    'README.md'
    'README.zh-CN.md'
    'CONTRIBUTING.md'
    'CONTRIBUTING.zh-CN.md'
    'SECURITY.md'
    'SECURITY.zh-CN.md'
    'CODE_OF_CONDUCT.md'
    'CODE_OF_CONDUCT.zh-CN.md'
)

function Get-RelativePath {
    [CmdletBinding()]
    param([string]$Full)
    return $Full.Substring($root.Length + 1).Replace('\', '/')
}

$include = New-Object System.Collections.Generic.List[string]
$unclassified = New-Object System.Collections.Generic.List[string]
$excluded = 0

foreach ($f in @(Get-ChildItem $root -Recurse -File -Force)) {
    $rel = Get-RelativePath $f.FullName
    $top = $rel.Split('/')[0]
    # Version-control internals are not files of this project, and dist/ is this
    # script's own output: neither belongs in a count of what was left out.
    if ($top -eq '.git' -or $top -eq 'dist') { continue }
    if ($ExcludeFile -contains $rel -or $ExcludeDir -contains $top) { $excluded++; continue }
    if ($IncludeFile -contains $rel -or $IncludeDir -contains $top) {
        [void]$include.Add($rel)
        continue
    }
    [void]$unclassified.Add($rel)
}

if ($unclassified.Count -gt 0) {
    throw ("unclassified file(s) -- add each one to the include or the exclude list in this script: " + ($unclassified -join ', '))
}

# The lists are only useful if they are complete: a missing entry here would
# otherwise ship a package that cannot start.
foreach ($rel in $IncludeFile) {
    if (-not $include.Contains($rel)) { throw "release package is missing a file it promises to ship: $rel" }
}
foreach ($dir in $IncludeDir) {
    $n = @($include | Where-Object { $_ -like "$dir/*" }).Count
    if ($n -eq 0) { throw "release package has no files under $dir/" }
    Write-Verbose ("  {0}/: {1} file(s)" -f $dir, $n)
}

# ---------------------------------------------------------------------------
# Build the archive.
# ---------------------------------------------------------------------------
$null = New-Item -ItemType Directory -Path $OutDir -Force
$zipPath = Join-Path $OutDir ("WinCleanKit-{0}.zip" -f $version)
if (Test-Path $zipPath) { Remove-Item $zipPath -Force }

# ZipArchiveMode lives in System.IO.Compression and ZipFile in
# System.IO.Compression.FileSystem; the second references the first, and
# Windows PowerShell 5.1 loads neither by default.
Add-Type -AssemblyName System.IO.Compression | Out-Null
Add-Type -AssemblyName System.IO.Compression.FileSystem | Out-Null
# Entry names always use forward slashes, whatever the build machine prefers, so
# the archive extracts correctly on Windows, macOS and Linux alike.
$prefix = "WinCleanKit-$version"
$archive = [System.IO.Compression.ZipFile]::Open($zipPath, [System.IO.Compression.ZipArchiveMode]::Create)
try {
    foreach ($rel in @($include | Sort-Object)) {
        $source = Join-Path $root ($rel.Replace('/', '\'))
        $shipped = if ($Rename.ContainsKey($rel)) { $Rename[$rel] } else { $rel }
        $entry = "$prefix/$shipped"
        if ($RewriteRootLinks -contains $rel) {
            # Written for the repository root, shipped at the package root: the same
            # text has to resolve in both, so the "../" comes off on the way in.
            $text = (Get-Content $source -Raw -Encoding UTF8).Replace('](../', '](')
            $handle = $archive.CreateEntry($entry, [System.IO.Compression.CompressionLevel]::Optimal)
            $writer = New-Object System.IO.StreamWriter($handle.Open(), (New-Object System.Text.UTF8Encoding($false)))
            try { $writer.Write($text) } finally { $writer.Dispose() }
            continue
        }
        [void][System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
            $archive, $source, $entry, [System.IO.Compression.CompressionLevel]::Optimal)
    }
} finally {
    $archive.Dispose()
}

$lines = New-Object System.Collections.Generic.List[string]
[void]$lines.Add("  version  : $version")
[void]$lines.Add("  files    : $($include.Count)")
[void]$lines.Add("  excluded : $excluded development file(s)")
[void]$lines.Add("  wrote    : $zipPath")

if (-not $NoHash) {
    $hash = (Get-FileHash -Path $zipPath -Algorithm SHA256).Hash.ToLowerInvariant()
    $sidecar = "$zipPath.sha256"
    # Two spaces between the hash and the name is what sha256sum -c expects.
    [IO.File]::WriteAllText($sidecar, "$hash  $([IO.Path]::GetFileName($zipPath))`n", (New-Object System.Text.UTF8Encoding($false)))
    [void]$lines.Add("  sha256   : $hash")
}

foreach ($line in $lines) { Write-Host $line }
