<#
.SYNOPSIS
    Verifies the release package: what a user downloads contains the product, and
    nothing that belongs to the repository.

.DESCRIPTION
    tools/New-ReleasePackage.ps1 decides what goes into the download, so this gate
    checks the thing it produced rather than the lists it used:

      * every file the product needs to start is in the archive
      * no development file is in it (tests, tools, CI, editor config, localization)
      * every entry sits under one top-level folder named after the engine version
      * the encoding that makes the shipped scripts work survives the packaging
        (BOM on .ps1, none on .bat, CRLF on .bat)
      * every relative link between the packaged documents resolves inside the
        package -- a download whose README points at files it does not contain is
        the failure this exists to catch
      * the .sha256 sidecar matches the archive it names

    It builds the package into a temporary folder and removes it afterwards, so it
    changes nothing in the repository.

.EXAMPLE
    .\tests\Test-Release.ps1
#>
[CmdletBinding()]
param()

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot

function Write-Head {
    param([string]$Text)
    Write-Host ''
    Write-Host "=== $Text ===" -ForegroundColor Cyan
}

$pass = 0
$fail = 0
function Check {
    param([string]$Name, [bool]$Ok, [string]$Detail = '')
    if ($Ok) { $script:pass++; Write-Host ("  [PASS] {0}{1}" -f $Name, $(if ($Detail) { " | $Detail" })) -ForegroundColor Green }
    else     { $script:fail++; Write-Host ("  [FAIL] {0}{1}" -f $Name, $(if ($Detail) { " | $Detail" })) -ForegroundColor Red }
}

# ---------------------------------------------------------------------------
Write-Head 'building the package'

$packager = Join-Path $root 'tools/New-ReleasePackage.ps1'
Check 'the packager exists' (Test-Path $packager) $packager
if (-not (Test-Path $packager)) {
    Write-Host ''
    Write-Host ("FAILED  pass={0} fail={1}" -f $pass, $fail) -ForegroundColor Red
    exit 1
}

$engineText = Get-Content (Join-Path $root 'src/WinCleanKit.ps1') -Raw -Encoding UTF8
$version = [regex]::Match($engineText, "EngineVersion\s*=\s*'([^']+)'").Groups[1].Value
Check 'the engine reports a version' ([bool]$version) $version

$tmp = Join-Path ([IO.Path]::GetTempPath()) ("wck-release-test-" + [Guid]::NewGuid().ToString('N').Substring(0, 8))
$null = New-Item -ItemType Directory -Path $tmp -Force

try {
    $null = & $packager -OutDir $tmp
    $zipPath = Join-Path $tmp ("WinCleanKit-{0}.zip" -f $version)
    Check 'the packager produced an archive' (Test-Path $zipPath) (Split-Path $zipPath -Leaf)
    if (-not (Test-Path $zipPath)) { throw "no archive at $zipPath" }

    Add-Type -AssemblyName System.IO.Compression | Out-Null
    Add-Type -AssemblyName System.IO.Compression.FileSystem | Out-Null
    $zip = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
    try {
        $entries = @($zip.Entries)
        $names = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
        foreach ($e in $entries) { [void]$names.Add($e.FullName) }

        Write-Head 'contents'
        $prefix = "WinCleanKit-$version/"
        $outside = @($entries | Where-Object { -not $_.FullName.StartsWith($prefix) })
        Check "every entry sits under $prefix" ($outside.Count -eq 0) (($outside | Select-Object -First 3 | ForEach-Object { $_.FullName }) -join ', ')

        # The four files the launcher checks for, the three it loads, the catalog
        # the engine reads, and the licence every copy has to carry.
        $required = @(
            'run.bat'
            'src/WinCleanKit.bat'
            'src/WinCleanKit.ps1'
            'src/menu/menu.ps1'
            'src/lib/Ui.Logic.ps1'
            'src/gui/WinCleanKit.gui.ps1'
            'src/lib/Tui.Render.ps1'
            'src/lib/Tui.Input.ps1'
            'catalog/catalog.json'
            'LICENSE'
            'README.md'
            'README.zh-CN.md'
            'CHANGELOG.md'
            'docs/USAGE.md'
            'docs/USAGE.zh-CN.md'
            'docs/SAFETY.md'
            'docs/LIMITATIONS.md'
            'docs/CATALOG.md'
        )
        $missing = @($required | Where-Object { -not $names.Contains($prefix + $_) })
        Check ('all {0} files the product needs are present' -f $required.Count) ($missing.Count -eq 0) ('missing: ' + ($missing -join ', '))

        $devDirs = @('tests', 'tools', 'localization', 'assets', '.github', '.gitea', '.vscode')
        # Contributor documents are left out too: someone who wants to run the tool
        # does not need the code of conduct, and the release front page does not
        # link to them.
        $devFiles = @(
            '.gitignore', '.gitattributes', '.editorconfig',
            'CONTRIBUTING.md', 'CONTRIBUTING.zh-CN.md',
            'SECURITY.md', 'SECURITY.zh-CN.md',
            'CODE_OF_CONDUCT.md', 'CODE_OF_CONDUCT.zh-CN.md',
            'release/README.md', 'release/README.zh-CN.md'
        )
        $leaked = @($entries | Where-Object {
            $rel = $_.FullName.Substring($prefix.Length)
            $top = $rel.Split('/')[0]
            ($devDirs -contains $top) -or ($devFiles -contains $rel) -or $rel.StartsWith('.git/')
        })
        Check 'no development file leaked into the package' ($leaked.Count -eq 0) (($leaked | Select-Object -First 5 | ForEach-Object { $_.FullName }) -join ', ')

        # The front page of the download is README.release.md renamed, not the project
        # page: the project page links to the contributor documents this package does
        # not contain, which the link check below would catch but only as a symptom.
        $frontEntry = $entries | Where-Object { $_.FullName -eq "${prefix}README.md" } | Select-Object -First 1
        $frontReader = New-Object System.IO.StreamReader($frontEntry.Open(), [Text.Encoding]::UTF8)
        try { $front = $frontReader.ReadToEnd() } finally { $frontReader.Dispose() }
        Check 'README.md is the release front page' ($front.Contains('front page of the downloadable package')) 'not the repository page'

        $empty = @($entries | Where-Object { $_.Length -eq 0 })
        Check 'no entry is empty' ($empty.Count -eq 0) (($empty | ForEach-Object { $_.FullName }) -join ', ')

        Write-Head 'the shipped files still carry the encoding that makes them work'
        function Get-EntryData {
            param($Entry)
            $stream = $Entry.Open()
            try {
                $ms = New-Object System.IO.MemoryStream
                $stream.CopyTo($ms)
                return $ms.ToArray()
            } finally { $stream.Dispose() }
        }
        function Test-IsBom {
            param([byte[]]$Bytes)
            return ($Bytes.Length -ge 3 -and $Bytes[0] -eq 0xEF -and $Bytes[1] -eq 0xBB -and $Bytes[2] -eq 0xBF)
        }
        function Test-HasCrlf {
            param([byte[]]$Bytes)
            for ($i = 0; $i -lt $Bytes.Length - 1; $i++) {
                if ($Bytes[$i] -eq 0x0D -and $Bytes[$i + 1] -eq 0x0A) { return $true }
            }
            return $false
        }

        $batBytes = Get-EntryData ($entries | Where-Object { $_.FullName -eq "${prefix}run.bat" } | Select-Object -First 1)
        Check 'run.bat ships without a BOM' (-not (Test-IsBom $batBytes)) 'a BOM would print as garbage before @echo off'
        Check 'run.bat ships with CRLF' (Test-HasCrlf $batBytes) 'cmd requires CRLF'

        $ps1Bytes = Get-EntryData ($entries | Where-Object { $_.FullName -eq "${prefix}src/WinCleanKit.ps1" } | Select-Object -First 1)
        Check 'the engine ships with its BOM' (Test-IsBom $ps1Bytes) 'without it PowerShell 5.1 decodes Chinese as ANSI'

        Write-Head 'the package documents itself'
        function Resolve-PackagePath {
            param([string]$BaseDir, [string]$Target)
            $parts = New-Object System.Collections.Generic.List[string]
            foreach ($p in $BaseDir.Split('/')) { if ($p) { [void]$parts.Add($p) } }
            foreach ($p in $Target.Split('/')) {
                if ($p -eq '' -or $p -eq '.') { continue }
                if ($p -eq '..') { if ($parts.Count -gt 0) { $parts.RemoveAt($parts.Count - 1) }; continue }
                [void]$parts.Add($p)
            }
            return ($parts -join '/')
        }

        $linkRe = [regex]'\]\(([^)\s#]+?)(#[^)\s]*)?\)'
        $broken = New-Object System.Collections.Generic.List[string]
        $checked = 0
        foreach ($e in @($entries | Where-Object { $_.FullName.EndsWith('.md') })) {
            $rel = $e.FullName.Substring($prefix.Length)
            $dir = ''
            if ($rel.Contains('/')) { $dir = $rel.Substring(0, $rel.LastIndexOf('/')) }
            $reader = New-Object System.IO.StreamReader($e.Open(), [Text.Encoding]::UTF8)
            try { $text = $reader.ReadToEnd() } finally { $reader.Dispose() }
            foreach ($m in $linkRe.Matches($text)) {
                $target = $m.Groups[1].Value
                if ($target -match '^[a-zA-Z][a-zA-Z0-9+.-]*:') { continue }
                $checked++
                $resolved = Resolve-PackagePath $dir $target
                if ($names.Contains($prefix + $resolved)) { continue }
                $asDir = ($prefix + $resolved).TrimEnd('/') + '/'
                if (@($entries | Where-Object { $_.FullName.StartsWith($asDir) }).Count -gt 0) { continue }
                [void]$broken.Add("$rel -> $target")
            }
        }
        Check ('all {0} relative links inside the package resolve' -f $checked) ($broken.Count -eq 0) (($broken | Select-Object -First 5) -join '; ')

        $changelogEntry = $entries | Where-Object { $_.FullName -eq "${prefix}CHANGELOG.md" } | Select-Object -First 1
        $clReader = New-Object System.IO.StreamReader($changelogEntry.Open(), [Text.Encoding]::UTF8)
        try { $changelog = $clReader.ReadToEnd() } finally { $clReader.Dispose() }
        Check 'the package documents the version it carries' ($changelog.Contains("## [$version]")) "## [$version]"
    } finally {
        $zip.Dispose()
    }

    Write-Head 'the checksum sidecar'
    $sidecar = "$zipPath.sha256"
    Check 'the sidecar was written' (Test-Path $sidecar) (Split-Path $sidecar -Leaf)
    if (Test-Path $sidecar) {
        $recorded = ((Get-Content $sidecar -Raw -Encoding UTF8).Trim() -split '\s+')[0]
        $actual = (Get-FileHash -Path $zipPath -Algorithm SHA256).Hash.ToLowerInvariant()
        Check 'the recorded hash matches the archive' ($recorded -eq $actual) ("recorded $($recorded.Substring(0, 12))... actual $($actual.Substring(0, 12))...")
    }
} finally {
    Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host ''
if ($fail -eq 0) { Write-Host ("ALL PASSED  ({0} checks)" -f $pass) -ForegroundColor Green }
else             { Write-Host ("FAILED  pass={0} fail={1}" -f $pass, $fail) -ForegroundColor Red }
exit $(if ($fail -eq 0) { 0 } else { 1 })
