<#
.SYNOPSIS
    WinCleanKit TUI - keyboard loop and terminal lifecycle.

.DESCRIPTION
    The thin, untestable part. Everything decidable lives in Tui.Logic.ps1; this
    file only:

      * prepares the terminal (enable VT processing, enter the alternate screen)
      * reads keys with [Console]::ReadKey($true)
      * maps a key to a call on the logic layer
      * repaints when the state changed
      * restores the terminal, always, via try/finally
      * hands the chosen plan to the engine when the user confirms

    TESTING NOTE, stated plainly: the key loop cannot be exercised by an automated
    run, because that needs a real interactive console. What is verified instead is
    the logic it dispatches to (tests/Test-Tui.ps1, 55 checks) plus static analysis.
    This file is kept deliberately small so there is little in it that could be
    wrong, and every failure path restores the terminal.

    If anything here misbehaves, `WinCleanKit.ps1 -NoTui` or `run.bat --simple`
    bypasses it entirely and uses the non-interactive path.

.NOTES
    Part of WinCleanKit. Requires Tui.Logic.ps1 and Tui.Render.ps1 loaded first.
#>

Set-StrictMode -Version 2.0

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
      Ask the legacy console host to interpret ANSI. Windows Terminal already does,
      so a failure here is not fatal: the caller falls back.
    #>
    [CmdletBinding()]
    param()
    try {
        $handle = [Tui.Native]::GetStdHandle(-11)          # STD_OUTPUT_HANDLE
        $mode = [uint32]0
        if (-not [Tui.Native]::GetConsoleMode($handle, [ref]$mode)) { return $false }
        # 0x0004 ENABLE_VIRTUAL_TERMINAL_PROCESSING
        if (($mode -band 0x0004) -ne 0) { return $true }
        return [Tui.Native]::SetConsoleMode($handle, ($mode -bor 0x0004))
    } catch {
        return $false
    }
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
    [Console]::Write("$esc[2J$esc[H")
}

function Exit-TuiScreen {
    [CmdletBinding()]
    param()
    $esc = [char]27
    try {
        [Console]::Write("$esc[0m")
        [Console]::Write("$esc[?1049l")     # back to the normal buffer
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
    param($Plan, [string]$Language, $Engine, [string]$Preset = 'balanced')
    try {
        # $Engine is a path, so invoke it explicitly as a script file.
        & powershell -NoProfile -ExecutionPolicy Bypass -File $Engine `
            -Plan -NoPrompt -Preset $Preset -Only $Plan -Language $Language
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
    $preset = $state.Preset
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
        $before = @{
            Select = $state.Selected.Count
            List   = $state.ListIndex
            Detail = $state.DetailIndex
            Mode   = $state.Mode
            Pane   = $state.Pane
            Msg    = $state.Message
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
                        else { Show-TuiPlan -Plan $plan -Language $state.Language -Engine $Engine -Preset $state.Preset; $lastFrame = '' }
                    }
                    'x' {
                        $plan = Get-TuiPlan $state
                        if ($plan.Count -eq 0) {
                            $state.Message = if ($state.Language -eq 'zh') { '没有选中任何项目' } else { 'nothing selected' }
                        } else {
                            $result = $plan
                            $preset = $state.Preset
                            return @{ Plan = $result; Preset = $preset; Language = $state.Language }
                        }
                    }
                    '1' { $state = Select-TuiPreset -State $state -Preset 'conservative' }
                    '2' { $state = Select-TuiPreset -State $state -Preset 'balanced' }
                    '3' { $state = Select-TuiPreset -State $state -Preset 'aggressive' }
                    'a' { $state = Switch-TuiGroupSelection -State $state -Selected $true }
                    'n' { $state = Switch-TuiGroupSelection -State $state -Selected $false }
                    'A' { $state = Switch-TuiAllSelection -State $state -Selected $true }
                    'N' { $state = Switch-TuiAllSelection -State $state -Selected $false }
                    'l' {
                        $next = if ($state.Language -eq 'zh') { 'en' } else { 'zh' }
                        $state = Select-TuiLanguage -State $state -Language $next
                        $lastFrame = ''
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

        $after = @{
            Select = $state.Selected.Count
            List   = $state.ListIndex
            Detail = $state.DetailIndex
            Mode   = $state.Mode
            Pane   = $state.Pane
            Msg    = $state.Message
        }
        foreach ($k in $before.Keys) {
            if ($before[$k] -ne $after[$k]) { $dirty = $true; break }
        }

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
        [string]$Preset = 'balanced',
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
    $state = Initialize-TuiState -Catalog $Catalog -Preset $Preset -Language $Language
    Enter-TuiScreen
    try {
        return Show-TuiInteraction -EngineState $state -Engine $Engine
    } finally {
        Exit-TuiScreen
    }
}
