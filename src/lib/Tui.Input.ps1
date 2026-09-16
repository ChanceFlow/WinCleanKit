<#
.SYNOPSIS
    WinCleanKit TUI - keyboard loop and terminal lifecycle.

.DESCRIPTION
    The thin, untestable part. Everything decidable lives in Ui.Logic.ps1; this
    file only:

      * prepares the terminal (enable VT processing, enter the alternate screen)
      * reads keys with [Console]::ReadKey($true)
      * maps a key to a call on the logic layer
      * repaints when the state changed
      * restores the terminal, always, via try/finally
      * hands the chosen plan to the engine when the user confirms

    TESTING NOTE, stated plainly: the key loop cannot be exercised by an automated
    run, because that needs a real interactive console. What is verified instead is
    the logic it dispatches to (tests/Test-Tui.ps1) and the frame contract
    (tests/Test-TuiRender.ps1) plus static analysis.
    This file is kept deliberately small so there is little in it that could be
    wrong, and every failure path restores the terminal.

    If anything here misbehaves, `WinCleanKit.ps1 -NoTui` or `run.bat --simple`
    bypasses it entirely and uses the non-interactive path.

.NOTES
    Part of WinCleanKit. Requires Ui.Logic.ps1 and Tui.Render.ps1 loaded first.
#>

Set-StrictMode -Version 2.0

$script:TuiSavedMode   = $null
$script:TuiSavedBuffer = $null

if (-not ('Tui.Native' -as [type])) {
    Add-Type -Namespace Tui -Name Native -MemberDefinition @'
[System.Runtime.InteropServices.DllImport("kernel32.dll", SetLastError=true)]
public static extern System.IntPtr GetStdHandle(int nStdHandle);

[System.Runtime.InteropServices.DllImport("kernel32.dll", SetLastError=true)]
public static extern bool GetConsoleMode(System.IntPtr hConsoleHandle, out uint lpMode);

[System.Runtime.InteropServices.DllImport("kernel32.dll", SetLastError=true)]
public static extern bool SetConsoleMode(System.IntPtr hConsoleHandle, uint dwMode);
'@
}

function Enable-TuiAnsi {
    <#
      Ask the legacy console host to interpret ANSI, and to stop advancing the
      cursor when a write reaches the last column. Windows Terminal already
      interprets ANSI, so a failure here is not fatal: the caller falls back.

      The mode the TUI asks for is computed by Get-TuiConsoleMode, which lives in
      the renderer and is pure, so the flags themselves are covered by a test.
    #>
    [CmdletBinding()]
    param()
    try {
        $handle = [Tui.Native]::GetStdHandle(-11)          # STD_OUTPUT_HANDLE
        $mode = [uint32]0
        if (-not [Tui.Native]::GetConsoleMode($handle, [ref]$mode)) { return $false }
        $script:TuiSavedMode = $mode
        $want = Get-TuiConsoleMode -Current $mode
        if ($mode -eq $want) { return $true }
        return [Tui.Native]::SetConsoleMode($handle, $want)
    } catch {
        return $false
    }
}

function Restore-TuiConsoleMode {
    <#
      Put the output mode back exactly as it was found. Never throws: this runs
      from a finally block, and an exception here would mask the real result.
    #>
    [CmdletBinding()]
    param()
    if ($null -eq $script:TuiSavedMode) { return }
    try {
        $handle = [Tui.Native]::GetStdHandle(-11)
        $null = [Tui.Native]::SetConsoleMode($handle, [uint32]$script:TuiSavedMode)
    } catch {
        $null = $_
    }
    $script:TuiSavedMode = $null
}

function Enter-TuiScreen {
    [CmdletBinding()]
    param()
    $esc = [char]27
    try { [Console]::CursorVisible = $false } catch {
        # Some hosts refuse cursor manipulation while a frame is being drawn.
        # Ignoring it is deliberate: a visible cursor is cosmetic, failing to
        # enter the screen would not be.
        $null = $_
    }
    # Alternate screen buffer: the user's scrollback survives the session.
    [Console]::Write("$esc[?1049h")
    # Automatic wrap off. A full-width row must leave the cursor on the last
    # column rather than move it to the next row.
    [Console]::Write("$esc[?7l")
    try {
        # Pin the buffer to the window, as Terminal.Gui does. With no buffer rows
        # below the window there is no scrollback for a stray line feed to scroll,
        # so even a mistake in a frame cannot make the screen creep.
        $script:TuiSavedBuffer = @([Console]::BufferWidth, [Console]::BufferHeight)
        [Console]::SetBufferSize([Console]::WindowWidth, [Console]::WindowHeight)
    } catch {
        $script:TuiSavedBuffer = $null
    }
    [Console]::Write("$esc[2J$esc[H")
}

function Exit-TuiScreen {
    [CmdletBinding()]
    param()
    $esc = [char]27
    try {
        [Console]::Write("$esc[0m")
        [Console]::Write("$esc[?7h")        # automatic wrap back on
        [Console]::Write("$esc[?1049l")     # back to the normal buffer
        if ($null -ne $script:TuiSavedBuffer) {
            [Console]::SetBufferSize($script:TuiSavedBuffer[0], $script:TuiSavedBuffer[1])
            $script:TuiSavedBuffer = $null
        }
        Restore-TuiConsoleMode
        [Console]::CursorVisible = $true
    } catch {
        # Restoring the terminal must never throw: if this fails the session is
        # ending anyway, and an exception here would mask the real result.
        $null = $_
    }
}

function Get-TuiSize {
    <#
      Current window size, with a sane floor so the layout maths never divides by
      something absurd after a resize.
    #>
    [CmdletBinding()]
    param()
    try {
        $w = [Console]::WindowWidth
        $h = [Console]::WindowHeight
    } catch {
        $w = 100; $h = 30
    }
    return @{ Width = [Math]::Max(60, $w); Height = [Math]::Max(18, $h) }
}

function Show-TuiPlan {
    <#
      Preview: the engine already renders the plan well, so reuse it rather than
      duplicating the presentation. The TUI is suspended while it prints.
    #>
    [CmdletBinding()]
    param($Plan, [string]$Language, $Engine)
    try {
        # $Engine is a path, so invoke it explicitly as a script file. -Only carries
        # the exact selection, so the preview shows precisely what is on screen.
        & powershell -NoProfile -ExecutionPolicy Bypass -File $Engine `
            -Plan -NoPrompt -Only $Plan -Language $Language
    } catch {
        Write-Host ("  preview failed: " + $_.Exception.Message) -ForegroundColor Red
    }
    Write-Host ''
    Write-Host '  (press any key to return)' -ForegroundColor DarkGray
    $null = [Console]::ReadKey($true)
}

function Show-TuiInteraction {
    <#
      Run the interactive loop until the user quits or confirms.

      Returns the plan to apply, or $null when the user quit without confirming.
      The caller owns execution: this function never changes the system.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] $EngineState,
        [Parameter(Mandatory)] [string]$Engine
    )

    $state = $EngineState
    $size = Get-TuiSize
    $lastFrame = ''
    $dirty = $true
    $result = $null
    $quit = $false

    while (-not $quit) {
        if ($dirty) {
            $frame = Get-TuiFrame -State $state -Width $size.Width -Height $size.Height
            $text = Format-TuiFrame -Lines $frame
            if ($text -ne $lastFrame) {
                [Console]::Write($text)
                $lastFrame = $text
            }
            $dirty = $false
        }

        $key = [Console]::ReadKey($true)
        # One stamp of everything the frame is drawn from, taken before the key is
        # handled and compared after. Listing the fields here by hand is what let
        # the language toggle repaint nothing, so the list lives in
        # Get-TuiRenderStamp, where a test can hold it to the renderer's own reads.
        $stamp = Get-TuiRenderStamp -State $state

        # The opening language chooser owns the keyboard until it is answered, so
        # it is handled before the main key map rather than inside it.
        if ($state.Mode -eq 'language') {
            switch ($key.Key) {
                'UpArrow'   { $state = Move-TuiLanguageCursor -State $state -Direction 'up' }
                'DownArrow' { $state = Move-TuiLanguageCursor -State $state -Direction 'down' }
                'Enter'     { $state = Select-TuiLanguageChoice -State $state -Language (Get-TuiLanguageChoice $state) }
                'Escape'    { $quit = $true }
                default {
                    if ($key.KeyChar -eq '1') { $state = Select-TuiLanguageChoice -State $state -Language 'zh' }
                    if ($key.KeyChar -eq '2') { $state = Select-TuiLanguageChoice -State $state -Language 'en' }
                    if ($key.KeyChar -eq 'q' -or $key.KeyChar -eq 'Q') { $quit = $true }
                }
            }
            $dirty = $true
            continue
        }

        switch ($key.Key) {
            'UpArrow'   { $state = Move-TuiCursor -State $state -Direction 'up' }
            'DownArrow' { $state = Move-TuiCursor -State $state -Direction 'down' }
            'Tab'       { $state = Switch-TuiPane -State $state }
            'Enter'     {
                if ($state.Pane -eq 'list') { $state = Switch-TuiPane -State $state }
                else { $state = Switch-TuiCurrent -State $state }
            }
            'Spacebar'  { $state = Switch-TuiCurrent -State $state }
            'Escape'    {
                if ($state.Mode -eq 'help') { $state = Select-TuiMode -State $state -Mode 'list' }
                else { $quit = $true }
            }
            'LeftArrow'  { $state = Select-TuiMode -State $state -Mode 'list' }
            'RightArrow' { $state = Select-TuiMode -State $state -Mode 'detail' }
            default {
                switch ($key.KeyChar) {
                    # Note: 'break' inside a switch leaves the switch, not the
                    # while loop, so quitting is expressed as a flag.
                    'q' { $quit = $true }
                    'Q' { $quit = $true }
                    'p' {
                        $plan = Get-TuiPlan $state
                        if ($plan.Count -eq 0) { $state.Message = if ($state.Language -eq 'zh') { '没有选中任何项目' } else { 'nothing selected' } }
                        else { Show-TuiPlan -Plan $plan -Language $state.Language -Engine $Engine; $dirty = $true }
                    }
                    'x' {
                        $plan = Get-TuiPlan $state
                        if ($plan.Count -eq 0) {
                            $state.Message = if ($state.Language -eq 'zh') { '没有选中任何项目' } else { 'nothing selected' }
                        } else {
                            $result = $plan
                            return @{ Plan = $result; Language = $state.Language }
                        }
                    }
                    'a' { $state = Switch-TuiGroupSelection -State $state -Selected $true }
                    'n' { $state = Switch-TuiGroupSelection -State $state -Selected $false }
                    'A' { $state = Switch-TuiAllSelection -State $state -Selected $true }
                    'N' { $state = Switch-TuiAllSelection -State $state -Selected $false }
                    'l' {
                        $next = if ($state.Language -eq 'zh') { 'en' } else { 'zh' }
                        $state = Select-TuiLanguage -State $state -Language $next
                    }
                    '?' { $state = Select-TuiMode -State $state -Mode 'help' }
                    default { }
                }
            }
        }

        # A resize invalidates the frame geometry.
        $now = Get-TuiSize
        if ($now.Width -ne $size.Width -or $now.Height -ne $size.Height) {
            $size = $now
            $dirty = $true
            $lastFrame = ''
        }

        if ((Get-TuiRenderStamp -State $state) -ne $stamp) { $dirty = $true }

    }
    return $null
}

function Show-TuiSession {
    <#
      Entry point. Prepares the terminal, runs the loop, restores the terminal, and
      returns the confirmed plan (or $null). Never changes the system itself.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] $Catalog,
        [Parameter(Mandatory)] [string]$Engine,
        [string]$Language = 'en'
    )

    # Three outcomes are reported distinctly so a caller can tell "cannot draw
    # here" from "the user quit": $script:TuiOutcome stays 3 for the former and
    # 0 for the latter. src\WinCleanKit.bat depends on that difference to decide
    # whether to fall back to the numbered menu.
    if (-not (Test-TuiSupported)) {
        $script:TuiOutcome = 3
        Write-Host '  [!] No interactive console, so the full-screen UI cannot start.' -ForegroundColor Yellow
        return $null
    }
    if (-not (Enable-TuiAnsi)) {
        $script:TuiOutcome = 3
        Write-Host '  [!] This console cannot render the full-screen UI.' -ForegroundColor Yellow
        return $null
    }

    $script:TuiOutcome = 0
    $state = Initialize-TuiState -Catalog $Catalog -Language $Language
    Enter-TuiScreen
    try {
        return Show-TuiInteraction -EngineState $state -Engine $Engine
    } finally {
        Exit-TuiScreen
    }
}
