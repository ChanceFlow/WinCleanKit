<#
.SYNOPSIS
    WinCleanKit TUI - pure logic layer.

.DESCRIPTION
    Everything about the interactive UI that can be decided without a terminal
    lives here, as pure functions over a plain hashtable:

      * navigation   (move the cursor, change mode, switch pane)
      * selection    (toggle an action, a category, or the whole catalog)
      * presets      (switch preset and re-resolve the selection)
      * layout math  (scroll windows, truncation, progress)

    No console API is touched in this file. That is deliberate: it is the reason
    the behaviour can be tested at all. The keyboard loop in Tui.Input.ps1 is
    thin glue around these functions, and tests/Test-Tui.ps1 exercises the logic
    without needing a terminal.

    State shape (a plain hashtable, so tests can construct one by hand):

        Catalog   object[]  actions from catalog.json
        Groups    object[]  one entry per category: id, name, zh, count
        Preset    string    conservative | balanced | aggressive
        Selected  hashtable id -> $true for every selected action
        Mode      string    list | detail | help
        ListIndex int       cursor in the category pane
        DetailIndex int     cursor in the action pane
        Pane      string    list | detail   (which pane has focus)
        Language  string    en | zh
        Message   string    transient status line
        ScrollTop int       first visible row of the action pane

.NOTES
    Part of WinCleanKit. Imports nothing and writes nothing.
#>

Set-StrictMode -Version 2.0

$script:PresetOrder = @('conservative', 'balanced', 'aggressive')

function Get-PresetList {
    <#
      The presets in escalation order, which is the order they must be shown in:
      a user should always read them from safest to most invasive.
    #>
    [CmdletBinding()]
    param()
    , $script:PresetOrder
}

function Get-PresetRank {
    <#
      Position of a preset in the escalation order, or -1 when unknown.
    #>
    [CmdletBinding()]
    param([string]$Preset)
    for ($i = 0; $i -lt $script:PresetOrder.Count; $i++) {
        if ($script:PresetOrder[$i] -eq $Preset) { return $i }
    }
    return -1
}

function Select-Preset {
    <#
      Resolve a preset into the selection map. This mirrors the engine's own
      resolution: a preset is the set of actions that name it.
    #>
    [CmdletBinding()]
    param($Catalog, [string]$Preset)

    $selected = @{}
    foreach ($a in $Catalog.actions) {
        if ($a.PSObject.Properties.Name -contains 'presets' -and $a.presets -and ($a.presets -contains $Preset)) {
            $selected[$a.id] = $true
        }
    }
    return $selected
}

function Initialize-TuiState {
    <#
      Build the initial state. Groups are precomputed so navigation never has to
      filter the catalog, and the counts they carry are what the list pane shows.
    #>
    [CmdletBinding()]
    param($Catalog, [string]$Preset = 'balanced', [string]$Language = 'en')

    $lang = $Language
    $groups = New-Object System.Collections.ArrayList
    foreach ($c in $Catalog.categories) {
        $items = @($Catalog.actions | Where-Object { $_.category -eq $c.id })
        if ($items.Count -eq 0) { continue }
        $name = $c.name
        if ($lang -eq 'zh' -and $c.PSObject.Properties.Name -contains 'name_zh' -and $c.name_zh) { $name = $c.name_zh }
        [void]$groups.Add([pscustomobject]@{
            id    = $c.id
            name  = $name
            count = $items.Count
        })
    }

    return @{
        Catalog     = $Catalog
        Groups      = $groups
        Preset      = $Preset
        Selected    = (Select-Preset -Catalog $Catalog -Preset $Preset)
        Mode        = 'list'
        ListIndex   = 0
        DetailIndex = 0
        Pane        = 'list'
        Language    = $lang
        Message     = ''
        ScrollTop   = 0
    }
}

function Get-TuiGroupAction {
    <#
      Actions belonging to the group under the cursor, in catalog order.
    #>
    [CmdletBinding()]
    param($State)

    if ($State.Groups.Count -eq 0) { return , @() }
    $gid = $State.Groups[$State.ListIndex].id
    , @($State.Catalog.actions | Where-Object { $_.category -eq $gid })
}

function Get-TuiActionAt {
    <#
      The action the detail cursor points at, or $null when the group is empty.
    #>
    [CmdletBinding()]
    param($State)
    $items = Get-TuiGroupAction $State
    if ($items.Count -eq 0) { return $null }
    $i = [Math]::Max(0, [Math]::Min($State.DetailIndex, $items.Count - 1))
    return $items[$i]
}

function Get-TuiSelectedCount {
    [CmdletBinding()]
    param($State)
    return $State.Selected.Count
}

function Test-TuiSelected {
    [CmdletBinding()]
    param($State, [string]$Id)
    return $State.Selected.ContainsKey($Id)
}

function Get-TuiHighestRisk {
    <#
      Highest risk among the selected actions, as a rank: 0 none, 1 low, 2 medium, 3 high.
      Used for the header, so the user always sees how much damage is armed.
    #>
    [CmdletBinding()]
    param($State)
    $order = @{ low = 1; medium = 2; high = 3 }
    $max = 0
    foreach ($a in $State.Catalog.actions) {
        if (-not $State.Selected.ContainsKey($a.id)) { continue }
        $r = $order[$a.risk]
        if ($r -gt $max) { $max = $r }
    }
    return $max
}

# --------------------------------------------------------------------------
# Navigation
# --------------------------------------------------------------------------

function Move-TuiCursor {
    <#
      Move the focused cursor by one step. Clamps rather than wraps: in a list of
      irreversible options, jumping from the last item back to the first is how
      people select the wrong thing.
    #>
    [CmdletBinding()]
    param($State, [ValidateSet('up', 'down')][string]$Direction)

    if ($State.Pane -eq 'list') {
        $n = $State.Groups.Count
        if ($n -eq 0) { return $State }
        if ($Direction -eq 'up')   { $State.ListIndex = [Math]::Max(0, $State.ListIndex - 1) }
        else                       { $State.ListIndex = [Math]::Min($n - 1, $State.ListIndex + 1) }
        # Changing group resets the action cursor, otherwise it can point past the end.
        $State.DetailIndex = 0
        $State.ScrollTop = 0
    } else {
        $items = Get-TuiGroupAction $State
        $n = $items.Count
        if ($n -eq 0) { return $State }
        if ($Direction -eq 'up')   { $State.DetailIndex = [Math]::Max(0, $State.DetailIndex - 1) }
        else                       { $State.DetailIndex = [Math]::Min($n - 1, $State.DetailIndex + 1) }
    }
    return $State
}

function Switch-TuiPane {
    [CmdletBinding()]
    param($State)
    if ($State.Mode -eq 'list') {
        $State.Pane = 'detail'
        $State.Mode = 'detail'
    } else {
        $State.Pane = 'list'
        $State.Mode = 'list'
    }
    return $State
}

function Select-TuiMode {
    [CmdletBinding()]
    param($State, [ValidateSet('list', 'detail', 'help')][string]$Mode)
    $State.Mode = $Mode
    if ($Mode -eq 'list') { $State.Pane = 'list' }
    if ($Mode -eq 'detail') { $State.Pane = 'detail' }
    return $State
}

function Select-TuiPreset {
    <#
      Switch preset. The selection is replaced wholesale, because a preset is a
      starting point, not an additive layer. Anything the user had customised is
      deliberately discarded, and the caller is expected to say so.
    #>
    [CmdletBinding()]
    param($State, [string]$Preset)
    if ((Get-PresetRank $Preset) -lt 0) { return $State }
    $State.Preset = $Preset
    $State.Selected = Select-Preset -Catalog $State.Catalog -Preset $Preset
    return $State
}

function Select-TuiLanguage {
    <#
      Switch language. Group labels are derived from the catalog, so they have to
      be rebuilt; the selection and cursors are preserved.
    #>
    [CmdletBinding()]
    param($State, [string]$Language)
    if ($Language -notin @('en', 'zh')) { return $State }
    $rebuilt = Initialize-TuiState -Catalog $State.Catalog -Preset $State.Preset -Language $Language
    $rebuilt.Selected    = $State.Selected
    $rebuilt.ListIndex   = [Math]::Min($State.ListIndex, [Math]::Max(0, $rebuilt.Groups.Count - 1))
    $rebuilt.DetailIndex = $State.DetailIndex
    $rebuilt.Message     = $State.Message
    # Where the user is standing is not part of the language. Rebuilding the state
    # resets these to the opening view, so without copying them back, switching
    # language from the detail pane or the help screen would throw the user back
    # to the list -- the one thing a language toggle must never do.
    $rebuilt.Mode        = $State.Mode
    $rebuilt.Pane        = $State.Pane
    $rebuilt.ScrollTop   = $State.ScrollTop
    return $rebuilt
}

# --------------------------------------------------------------------------
# Terminal detection (still pure: it inspects the environment, never the screen)
# --------------------------------------------------------------------------

function Test-TuiSupported {
    <#
      Whether a full-screen TUI can be drawn at all.

      A redirected stdout, or a host with no interactive console, cannot be drawn
      into: painting a frame would just dump escape codes into a log. Callers must
      fall back to plain output rather than assuming this succeeds.
    #>
    [CmdletBinding()]
    param()
    try {
        if ([Console]::IsOutputRedirected) { return $false }
        if (-not [Environment]::UserInteractive) { return $false }
        if ($Host.Name -eq 'ServerRemoteHost') { return $false }
    } catch {
        # If any probe is unavailable, assume it cannot be drawn.
        return $false
    }
    return $true
}

# --------------------------------------------------------------------------
# Selection
# --------------------------------------------------------------------------

function Switch-TuiAction {
    <#
      Flip one action. This is the operation the whole redesign exists for, so it
      is a pure function that a test can call directly.
    #>
    [CmdletBinding()]
    param($State, [string]$Id)
    if ($State.Selected.ContainsKey($Id)) { $State.Selected.Remove($Id) | Out-Null }
    else { $State.Selected[$Id] = $true }
    return $State
}

function Switch-TuiCurrent {
    <#
      Flip the action under the cursor and step down one row, so repeated presses
      walk the list while selecting.
    #>
    [CmdletBinding()]
    param($State)
    $a = Get-TuiActionAt $State
    if (-not $a) { return $State }
    $State = Switch-TuiAction -State $State -Id $a.id
    $items = Get-TuiGroupAction $State
    if ($State.DetailIndex -lt ($items.Count - 1)) { $State.DetailIndex++ }
    return $State
}

function Switch-TuiGroupSelection {
    <#
      Select or clear every action in the group under the cursor.
    #>
    [CmdletBinding()]
    param($State, [bool]$Selected)
    foreach ($a in (Get-TuiGroupAction $State)) {
        if ($Selected) { $State.Selected[$a.id] = $true }
        else           { if ($State.Selected.ContainsKey($a.id)) { $State.Selected.Remove($a.id) | Out-Null } }
    }
    return $State
}

function Switch-TuiAllSelection {
    [CmdletBinding()]
    param($State, [bool]$Selected)
    if ($Selected) {
        foreach ($a in $State.Catalog.actions) { $State.Selected[$a.id] = $true }
    } else {
        $State.Selected = @{}
    }
    return $State
}

function Get-TuiGroupSelection {
    <#
      How many actions in the group under the cursor are selected, plus the total.
      The list pane renders this as a progress-style "4/22".
    #>
    [CmdletBinding()]
    param($State)
    $items = Get-TuiGroupAction $State
    $on = 0
    foreach ($a in $items) { if ($State.Selected.ContainsKey($a.id)) { $on++ } }
    return @{ Selected = $on; Total = $items.Count }
}

function Get-TuiPlan {
    <#
      The concrete list of action ids to hand to the engine, in catalog order.
      This is the contract between the UI and the executor.
    #>
    [CmdletBinding()]
    param($State)
    , @($State.Catalog.actions | Where-Object { $State.Selected.ContainsKey($_.id) } | ForEach-Object { $_.id })
}

# --------------------------------------------------------------------------
# Layout math (pure, so the windowing can be tested without a terminal)
# --------------------------------------------------------------------------

function Get-TuiWindow {
    <#
      Which slice of a list of $Total rows fits in $Height rows with the cursor at
      $Cursor, keeping the cursor visible. Returns the first visible index.
    #>
    [CmdletBinding()]
    param([int]$Total, [int]$Height, [int]$Cursor, [int]$ScrollTop = 0)
    if ($Height -le 0 -or $Total -le 0) { return 0 }
    $top = [Math]::Max(0, [Math]::Min($ScrollTop, [Math]::Max(0, $Total - $Height)))
    if ($Cursor -lt $top) { $top = $Cursor }
    if ($Cursor -ge ($top + $Height)) { $top = $Cursor - $Height + 1 }
    return [Math]::Max(0, [Math]::Min($top, [Math]::Max(0, $Total - $Height)))
}

function Get-TuiScrollTop {
    <#
      The scroll offset that keeps the current detail cursor visible in $Height rows.
    #>
    [CmdletBinding()]
    param($State, [int]$Height)
    $items = Get-TuiGroupAction $State
    return (Get-TuiWindow -Total $items.Count -Height $Height -Cursor $State.DetailIndex -ScrollTop $State.ScrollTop)
}
