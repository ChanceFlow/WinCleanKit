<#
.SYNOPSIS
    Verifies on a real console that repainting the TUI never scrolls the screen.

.DESCRIPTION
    This is the one thing the automated gates cannot check. tests/Test-TuiRender.ps1
    proves the frame is the right size and shape and that Format-TuiFrame emits the
    right escape sequences, but only the terminal itself can say whether painting
    those sequences scrolls the screen.

    Run it in a real console window (not the ISE, not a redirected pipe):

        .\tools\Test-TuiScroll.ps1

    How it works: it paints a frame whose every row carries its own row number,
    repaints it, then reads the console buffer back and compares all rows against
    the frame it intended to draw. Any scroll shows up immediately as a row
    mismatch.

    It draws the frame twice, two ways:

      * "legacy" - home the cursor, then write each row followed by ESC[K and CRLF.
        This is the painter that shipped first, and it is kept here as the control:
        a screen that fills the last row and then emits a line feed has advanced
        past the bottom line, so the console scrolls and the whole frame sits one
        row too high on every single repaint. The test FAILS the run if this
        control does not reproduce that, because a passing test that cannot detect
        the bug it exists for is worthless.

      * "current" - Format-TuiFrame from src/lib/Tui.Render.ps1, which positions
        every row absolutely and never writes a line feed.

    The approach is the one Terminal.Gui's NetDriver uses - the driver behind
    Microsoft's Out-ConsoleGridView: absolute per-row positioning, no newlines, the
    DISABLE_NEWLINE_AUTO_RETURN output mode, and the screen buffer pinned to the
    window size so there is no scrollback for a stray line feed to scroll.

.EXAMPLE
    .\tools\Test-TuiScroll.ps1
    Runs the check and prints a pass/fail report.

.NOTES
    Part of WinCleanKit. Exits 0 when the current painter is clean and the control
    reproduces the defect; 1 otherwise. Not part of CI: it needs a real console.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Continue'

$root = Split-Path -Parent $PSScriptRoot
. (Join-Path $root 'src/lib/Tui.Logic.ps1')
. (Join-Path $root 'src/lib/Tui.Render.ps1')
. (Join-Path $root 'src/lib/Tui.Input.ps1')

# The dot-sourced files turn on Set-StrictMode, so everything this script reads has
# to exist first.
$script:ProbeCellGrid = $null
$script:Esc = [char]27

function Write-ProbeHead {
    param([string]$Text)
    Write-Host ''
    Write-Host "=== $Text ===" -ForegroundColor Cyan
}

function Read-TuiScreen {
    <#
      The whole visible window as an array of strings, one per row.
    #>
    [CmdletBinding()]
    param()
    $raw = $Host.UI.RawUI
    $w = [int]$raw.WindowSize.Width
    $h = [int]$raw.WindowSize.Height
    $rect = New-Object Management.Automation.Host.Rectangle 0, 0, ($w - 1), ($h - 1)
    $cells = $raw.GetBufferContents($rect)
    $dim0 = $cells.GetLength(0)
    $dim1 = $cells.GetLength(1)
    if (-not $script:ProbeCellGrid) { $script:ProbeCellGrid = "cell grid ${dim0}x${dim1} for a window of ${w}x${h}" }
    # GetBufferContents returns a 2-D array. GetValue keeps this readable: indexing
    # with $cells[$c, $r] inside a method argument is parsed as two arguments.
    $byColumn = ($dim0 -eq $w)
    $rows = @()
    for ($r = 0; $r -lt $h; $r++) {
        $sb = New-Object System.Text.StringBuilder
        for ($c = 0; $c -lt $w; $c++) {
            $cell = if ($byColumn) { $cells.GetValue($c, $r) } else { $cells.GetValue($r, $c) }
            [void]$sb.Append($cell.Character)
        }
        $rows += $sb.ToString()
    }
    return $rows
}

function Compare-TuiScreen {
    <#
      How many rows of the live screen disagree with the frame that was painted.
    #>
    [CmdletBinding()]
    param([string[]]$Expected)
    $actual = Read-TuiScreen
    $diff = @()
    for ($i = 0; $i -lt $Expected.Count; $i++) {
        $a = if ($i -lt $actual.Count) { $actual[$i] } else { '<missing>' }
        if ($a -ne $Expected[$i]) { $diff += $i }
    }
    if ($diff.Count -gt 0) {
        $i = $diff[0]
        $want = $Expected[$i].Substring(0, [Math]::Min(28, $Expected[$i].Length))
        $got  = $actual[$i].Substring(0, [Math]::Min(28, $actual[$i].Length))
        Write-Host ("       first mismatch at row {0}: want '{1}' got '{2}'" -f $i, $want, $got) -ForegroundColor DarkGray
    }
    return $diff.Count
}

function Format-LegacyFrame {
    <#
      The painter this test exists to catch: home, then every row followed by ESC[K
      and CRLF. Kept verbatim so the control always reproduces the defect.
    #>
    [CmdletBinding()]
    param([string[]]$Lines)
    $e = [char]27
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.Append("$e[?25l")
    [void]$sb.Append("$e[H")
    foreach ($l in $Lines) {
        [void]$sb.Append($l)
        [void]$sb.Append("$e[K`r`n")
    }
    [void]$sb.Append("$e[?25h")
    return $sb.ToString()
}

$fail = 0
$raw = $Host.UI.RawUI
$w = [int]$raw.WindowSize.Width
$h = [int]$raw.WindowSize.Height

Write-ProbeHead 'console'
if ([Console]::IsOutputRedirected) {
    Write-Host '  [FAIL] stdout is redirected; this check needs a real console window.' -ForegroundColor Red
    Write-Host '         Run it from a normal console, not from a pipe or a log file.'
    exit 1
}
$null = Read-TuiScreen
Write-Host ("  window {0}x{1}, buffer {2}x{3}" -f $w, $h, $raw.BufferSize.Width, $raw.BufferSize.Height)
Write-Host ("  {0}" -f $script:ProbeCellGrid)

$marker = @()
for ($i = 0; $i -lt $h; $i++) { $marker += (("R{0:D2}" -f $i) + ('.' * ($w - 6)) + 'END') }

# ---------------------------------------------------------------------------
Write-ProbeHead 'the control: the legacy painter must be caught'
[Console]::Write("$script:Esc[?1049h")
$legacyWorst = 0
foreach ($paints in 1, 3) {
    for ($k = 0; $k -lt $paints; $k++) {
        [Console]::Write((Format-LegacyFrame $marker))
        Start-Sleep -Milliseconds 40
    }
    Start-Sleep -Milliseconds 150
    $bad = Compare-TuiScreen -Expected $marker
    if ($bad -gt $legacyWorst) { $legacyWorst = $bad }
    Write-Host ("  legacy, {0} paint(s): {1}/{2} rows wrong" -f $paints, $bad, $h)
}
[Console]::Write("$script:Esc[0m$script:Esc[?1049l")
Start-Sleep -Milliseconds 250
if ($legacyWorst -eq 0) {
    $fail++
    Write-Host '  [FAIL] the control did not reproduce the scroll, so this test proves nothing.' -ForegroundColor Red
} else {
    Write-Host '  [PASS] the control scrolls, so a clean result below means something.' -ForegroundColor Green
}

# ---------------------------------------------------------------------------
Write-ProbeHead 'the current painter must not scroll'
$ansi = Enable-TuiAnsi
if (-not $ansi) {
    $fail++
    Write-Host '  [FAIL] could not put the console into the mode the TUI needs.' -ForegroundColor Red
} else {
    Write-Host '  [PASS] console mode accepted' -ForegroundColor Green
}
Enter-TuiScreen
$pinned = ($raw.BufferSize.Width -eq $w -and $raw.BufferSize.Height -eq $h)
Write-Host ("  buffer pinned to the window: {0}x{1} -> {2}" -f $raw.BufferSize.Width, $raw.BufferSize.Height, $pinned)
if (-not $pinned) {
    Write-Host '  [warn] the buffer is taller than the window here; the painter must still not scroll.' -ForegroundColor Yellow
}
foreach ($paints in 1, 3, 25) {
    for ($k = 0; $k -lt $paints; $k++) {
        [Console]::Write((Format-TuiFrame -Lines $marker))
        Start-Sleep -Milliseconds 25
    }
    Start-Sleep -Milliseconds 150
    $bad = Compare-TuiScreen -Expected $marker
    if ($bad -eq 0) {
        Write-Host ("  [PASS] {0} paint(s): the screen still equals the frame" -f $paints) -ForegroundColor Green
    } else {
        $fail++
        Write-Host ("  [FAIL] {0} paint(s): {1}/{2} rows wrong" -f $paints, $bad, $h) -ForegroundColor Red
    }
}
Exit-TuiScreen
Start-Sleep -Milliseconds 250

# ---------------------------------------------------------------------------
Write-ProbeHead 'the real frame, with the cursor moving'
$catalog = Get-Content (Join-Path $root 'catalog/catalog.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$state = Initialize-TuiState -Catalog $catalog -Preset 'balanced' -Language 'en'
$null = Enable-TuiAnsi
Enter-TuiScreen
$last = $null
foreach ($k in 0..29) {
    $state.DetailIndex = $k % 22
    $state.ListIndex = $k % 4
    $last = Get-TuiFrame -State $state -Width $w -Height $h
    [Console]::Write((Format-TuiFrame -Lines $last))
    Start-Sleep -Milliseconds 25
}
Start-Sleep -Milliseconds 200
$bad = Compare-TuiScreen -Expected $last
Exit-TuiScreen
if ($bad -eq 0) {
    Write-Host '  [PASS] 30 repaints with the cursor moving: the screen still equals the frame' -ForegroundColor Green
} else {
    $fail++
    Write-Host ("  [FAIL] {0}/{1} rows wrong" -f $bad, $h) -ForegroundColor Red
}

Write-Host ''
if ($fail -eq 0) { Write-Host 'ALL PASSED' -ForegroundColor Green }
else             { Write-Host ("FAILED  ({0} problem(s))" -f $fail) -ForegroundColor Red }
exit $(if ($fail -eq 0) { 0 } else { 1 })
