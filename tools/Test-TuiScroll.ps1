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
        row too high on every single repaint. The test FAILS the run if this control
        does not reproduce that, because a passing test that cannot detect the bug
        it exists for is worthless.

      * "current" - Format-TuiFrame from src/lib/Tui.Render.ps1, which positions
        every row absolutely and never writes a line feed.

    The approach is the one Terminal.Gui's NetDriver uses - the driver behind
    Microsoft's Out-ConsoleGridView: absolute per-row positioning, no newlines, the
    DISABLE_NEWLINE_AUTO_RETURN output mode, and the screen buffer pinned to the
    window size so there is no scrollback for a stray line feed to scroll.

.PARAMETER LogPath
    Also append the report to this file. Use it when something else reads the
    result, for example a scheduled task whose window is hidden. Standard output
    stays on the console either way: redirecting it would make the check refuse to
    run, because a redirected stdout means there is no console to check.

.EXAMPLE
    .\tools\Test-TuiScroll.ps1

.EXAMPLE
    .\tools\Test-TuiScroll.ps1 -LogPath "$env:TEMP\wck-tool.log"

.NOTES
    Part of WinCleanKit. Exits 0 when the current painter is clean and the control
    reproduces the defect; 1 otherwise. Not part of CI: it needs a real console.
#>
[CmdletBinding()]
param(
    [string]$LogPath
)

$ErrorActionPreference = 'Continue'

$root = Split-Path -Parent $PSScriptRoot
. (Join-Path $root 'src/lib/Tui.Logic.ps1')
. (Join-Path $root 'src/lib/Tui.Render.ps1')
. (Join-Path $root 'src/lib/Tui.Input.ps1')

# The dot-sourced files turn on Set-StrictMode, so everything this script reads has
# to exist first.
$script:ProbeCellGrid = $null
$script:ProbeLog = $LogPath
$script:Esc = [char]27

if ($script:ProbeLog) {
    Set-Content -Path $script:ProbeLog -Value 'WinCleanKit console paint check' -Encoding UTF8
}

function Write-ProbeReport {
    param([string]$Text, [string]$Colour = 'Gray')
    Write-Host $Text -ForegroundColor $Colour
    if ($script:ProbeLog) { Add-Content -Path $script:ProbeLog -Value $Text -Encoding UTF8 }
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
        Write-ProbeReport ("       first mismatch at row {0}: want '{1}' got '{2}'" -f $i, $want, $got) 'DarkGray'
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

Write-ProbeReport ''
Write-ProbeReport '=== console ===' 'Cyan'
if ([Console]::IsOutputRedirected) {
    Write-ProbeReport '  [FAIL] stdout is redirected; this check needs a real console window.' 'Red'
    Write-ProbeReport '         Run it from a normal console. To capture the report too, pass' 'Red'
    Write-ProbeReport '         -LogPath instead of redirecting stdout.' 'Red'
    exit 1
}
$null = Read-TuiScreen
Write-ProbeReport ("  window {0}x{1}, buffer {2}x{3}" -f $w, $h, $raw.BufferSize.Width, $raw.BufferSize.Height)
Write-ProbeReport ("  {0}" -f $script:ProbeCellGrid)

$marker = @()
for ($i = 0; $i -lt $h; $i++) { $marker += (("R{0:D2}" -f $i) + ('.' * ($w - 6)) + 'END') }

# ---------------------------------------------------------------------------
Write-ProbeReport ''
Write-ProbeReport '=== the control: the legacy painter must be caught ===' 'Cyan'
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
    Write-ProbeReport ("  legacy, {0} paint(s): {1}/{2} rows wrong" -f $paints, $bad, $h)
}
[Console]::Write("$script:Esc[0m$script:Esc[?1049l")
Start-Sleep -Milliseconds 250
if ($legacyWorst -eq 0) {
    $fail++
    Write-ProbeReport '  [FAIL] the control did not reproduce the scroll, so this test proves nothing.' 'Red'
} else {
    Write-ProbeReport '  [PASS] the control scrolls, so a clean result below means something.' 'Green'
}

# ---------------------------------------------------------------------------
Write-ProbeReport ''
Write-ProbeReport '=== the current painter must not scroll ===' 'Cyan'
if (-not (Enable-TuiAnsi)) {
    $fail++
    Write-ProbeReport '  [FAIL] could not put the console into the mode the TUI needs.' 'Red'
} else {
    Write-ProbeReport '  [PASS] console mode accepted' 'Green'
}
Enter-TuiScreen
$pinned = ($raw.BufferSize.Width -eq $w -and $raw.BufferSize.Height -eq $h)
Write-ProbeReport ("  buffer pinned to the window: {0}x{1} -> {2}" -f $raw.BufferSize.Width, $raw.BufferSize.Height, $pinned)
if (-not $pinned) {
    Write-ProbeReport '  [warn] the buffer is taller than the window here; the painter must still not scroll.' 'Yellow'
}
foreach ($paints in 1, 3, 25) {
    for ($k = 0; $k -lt $paints; $k++) {
        [Console]::Write((Format-TuiFrame -Lines $marker))
        Start-Sleep -Milliseconds 25
    }
    Start-Sleep -Milliseconds 150
    $bad = Compare-TuiScreen -Expected $marker
    if ($bad -eq 0) {
        Write-ProbeReport ("  [PASS] {0} paint(s): the screen still equals the frame" -f $paints) 'Green'
    } else {
        $fail++
        Write-ProbeReport ("  [FAIL] {0} paint(s): {1}/{2} rows wrong" -f $paints, $bad, $h) 'Red'
    }
}
Exit-TuiScreen
Start-Sleep -Milliseconds 250

# ---------------------------------------------------------------------------
Write-ProbeReport ''
Write-ProbeReport '=== the real frame, with the cursor moving ===' 'Cyan'
$catalog = Get-Content (Join-Path $root 'catalog/catalog.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$state = Initialize-TuiState -Catalog $catalog -Language 'en'
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
    Write-ProbeReport '  [PASS] 30 repaints with the cursor moving: the screen still equals the frame' 'Green'
} else {
    $fail++
    Write-ProbeReport ("  [FAIL] {0}/{1} rows wrong" -f $bad, $h) 'Red'
}

Write-ProbeReport ''
if ($fail -eq 0) { Write-ProbeReport 'ALL PASSED' 'Green' }
else             { Write-ProbeReport ("FAILED  ({0} problem(s))" -f $fail) 'Red' }
exit $(if ($fail -eq 0) { 0 } else { 1 })
