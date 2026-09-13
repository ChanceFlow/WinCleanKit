<#
.SYNOPSIS
    WinCleanKit TUI - renderer.

.DESCRIPTION
    Turns a state object from Tui.Logic.ps1 into a frame of text lines. This file
    does no drawing and reads no keys: it builds an array of strings and hands it
    back, so the layout can be exercised without a terminal and there is only one
    place that knows about ANSI.

    Frame layout (width x height, minimum 60x18):

        +----------------------------------------------------------------+
        | WinCleanKit  v0.1.0   preset [balanced]   plan: 60 actions     |  header
        | highest risk: medium                              EN | zh      |
        +--------------------------+-------------------------------------+
        | > 22/22 系统广告与推荐    | [ ] 禁止静默自动安装应用             |  body
        |   0/21  遥测与诊断数据    |                                     |
        |   ...                    | Why: ...                            |
        |                          | Cost: ...                           |
        |                          | Sets: HKCU\...\SilentInstall...     |
        +--------------------------+-------------------------------------+
        | up/down move  space toggle  ...                                |  keys
        | [ok] preset balanced applied                                   |  status
        +----------------------------------------------------------------+

.NOTES
    Part of WinCleanKit. Requires Tui.Logic.ps1 to be loaded first.
#>

Set-StrictMode -Version 2.0

$script:Esc = [char]27

function Get-TuiWidth {
    <#
      Visual width in terminal columns. Duplicated from the engine on purpose: a
      library file must not depend on the engine being dot-sourced, and this is
      the one primitive the whole layout rests on.
    #>
    [CmdletBinding()]
    param([string]$Text)
    if (-not $Text) { return 0 }
    $w = 0
    foreach ($ch in $Text.ToCharArray()) {
        $c = [int]$ch
        if (($c -ge 0x1100 -and $c -le 0x115F) -or
            ($c -ge 0x2E80 -and $c -le 0xA4CF) -or
            ($c -ge 0xAC00 -and $c -le 0xD7A3) -or
            ($c -ge 0xF900 -and $c -le 0xFAFF) -or
            ($c -ge 0xFE30 -and $c -le 0xFE6F) -or
            ($c -ge 0xFF00 -and $c -le 0xFF60) -or
            ($c -ge 0xFFE0 -and $c -le 0xFFE6)) { $w += 2 }
        elseif (($c -ge 0x0300 -and $c -le 0x036F)) { }
        else { $w += 1 }
    }
    return $w
}

function Format-TuiCell {
    <#
      Fit a string into an exact display width: pad with spaces, or truncate with
      an ellipsis. Chinese glyphs are two columns wide, so padding by character
      count would leave the border ragged.
    #>
    [CmdletBinding()]
    param([string]$Text, [int]$Width)
    if ($null -eq $Text) { $Text = '' }
    # A frame is a single line: never let a stray newline split it.
    $Text = ($Text -replace '[\r\n]+', ' ')
    $w = Get-TuiWidth $Text
    if ($w -le $Width) { return $Text + (' ' * ($Width - $w)) }
    $out = ''
    $used = 0
    foreach ($ch in $Text.ToCharArray()) {
        $c = Get-TuiWidth ([string]$ch)
        if (($used + $c) -gt ($Width - 1)) { break }
        $out += $ch
        $used += $c
    }
    return $out + ([char]0x2026) + (' ' * [Math]::Max(0, $Width - $used - 1))
}

function Get-TuiText {
    <#
      Localise a catalog object, preferring the Chinese field when asked for it.
    #>
    [CmdletBinding()]
    param($Object, [string]$Base, [string]$Language)
    if ($Language -eq 'zh') {
        $alt = "${Base}_zh"
        if ($Object.PSObject.Properties.Name -contains $alt -and $Object.$alt) { return $Object.$alt }
    }
    return $Object.$Base
}

function Get-TuiWrap {
    <#
      Break text into at most $Max lines that each fit $Width display columns.

      Wrapping is by display width rather than character count, so Chinese text
      does not overshoot the pane border. When there is more text than fits, the
      last line ends in an ellipsis: a sentence that was cut is then visibly cut,
      instead of the reader wondering whether the rationale was empty.
    #>
    [CmdletBinding()]
    param([string]$Text, [int]$Width, [int]$Max)

    $lines = New-Object System.Collections.Generic.List[string]
    if ([string]::IsNullOrEmpty($Text) -or $Width -lt 2 -or $Max -lt 1) { return , $lines.ToArray() }

    $chars = ($Text -replace '[\r\n]+', ' ').Trim().ToCharArray()
    $cur = ''
    $used = 0
    $i = 0
    while ($i -lt $chars.Count) {
        $ch = [string]$chars[$i]
        $cw = Get-TuiWidth $ch
        if (($used + $cw) -gt $Width) {
            [void]$lines.Add($cur)
            $cur = ''
            $used = 0
            if ($lines.Count -ge $Max) { break }
            # Do not advance: re-test this character on the line just started.
            continue
        }
        $cur += $ch
        $used += $cw
        $i++
    }
    if ($lines.Count -lt $Max -and $used -gt 0) { [void]$lines.Add($cur) }

    if ($i -lt $chars.Count -and $lines.Count -gt 0) {
        $last = $lines[$lines.Count - 1]
        while ($last.Length -gt 0 -and (Get-TuiWidth $last) -gt ($Width - 1)) {
            $last = $last.Substring(0, $last.Length - 1)
        }
        $lines[$lines.Count - 1] = $last + [char]0x2026
    }
    return , $lines.ToArray()
}

function Get-TuiTargetLine {
    <#
      One line describing what an action actually does, so the detail pane answers
      "what will this touch?" without the user opening the catalog.
    #>
    [CmdletBinding()]
    param($Action)
    switch ($Action.target) {
        'registry'   { return ("{0}\{1}\{2} = {3}" -f $Action.hive, $Action.key, $Action.name, $Action.value) }
        'service'    { return ("service {0} -> {1}" -f $Action.name, $Action.startType) }
        'task'       { return ("task {0}{1}" -f $Action.path, $Action.name) }
        'appx'       { return ("uninstall {0} + revoke provisioning" -f $Action.name) }
        'path-clean' { return ("delete cache: " + (($Action.paths | ForEach-Object { Split-Path $_ -Leaf }) -join ', ')) }
        'onedrive'   { return 'remove OneDrive client, block reinstall (data folder untouched)' }
        default      { return $Action.target }
    }
}

function Get-TuiKeyHelp {
    [CmdletBinding()]
    param([string]$Language, [int]$Width)
    if ($Language -eq 'zh') {
        $full  = '上下移动  Tab切换面板  Enter进入/勾选  空格勾选  a全选 n全不选  1/2/3预设  l语言  ?帮助  p预览  x执行  q退出'
        $short = '上下移动  Tab面板  Enter勾选  1/2/3预设  ?帮助  x执行  q退出'
    } else {
        $full  = 'up/down move  Tab pane  Enter enter/toggle  space toggle  a all  n none  1/2/3 preset  l lang  ? help  p preview  x apply  q quit'
        $short = 'up/down move  Tab pane  Enter toggle  1/2/3 preset  ? help  x apply  q quit'
    }
    if ($Width -ge (Get-TuiWidth $full)) { return $full }
    return $short
}

function Get-TuiFrame {
    <#
      Build one frame as an array of strings, each exactly $Width columns wide.
      Pure: given the same state and size it always returns the same lines.
    #>
    [CmdletBinding()]
    param($State, [int]$Width, [int]$Height, [string]$Version = '0.1.0')

    $zh = ($State.Language -eq 'zh')
    $w = [Math]::Max(60, $Width)
    $h = [Math]::Max(18, $Height)
    $inner = $w - 2                 # usable width inside the borders
    $lines = New-Object System.Collections.Generic.List[string]

    # ---- header -----------------------------------------------------------
    $title = if ($zh) { 'WinCleanKit' } else { 'WinCleanKit' }
    $presetLabel = if ($zh) { '预设' } else { 'preset' }
    $planLabel   = if ($zh) { '计划' } else { 'plan' }
    $riskNames   = if ($zh) { @('无', '低', '中', '高') } else { @('none', 'low', 'medium', 'high') }
    $risk = Get-TuiHighestRisk $State
    $count = Get-TuiSelectedCount $State

    $riskText = if ($zh) { "最高风险: $($riskNames[$risk])" } else { "highest risk: $($riskNames[$risk])" }
    $planText = "{0}: {1} {2}" -f $planLabel, $count, $(if ($zh) { '项' } else { 'actions' })

    [void]$lines.Add('+' + ('-' * $inner) + '+')
    $row1 = " {0} v{1}   {2} [{3}]   {4}" -f $title, $Version, $presetLabel, $State.Preset, $planText
    $row2 = " {0}" -f $riskText
    [void]$lines.Add('|' + (Format-TuiCell $row1 $inner) + '|')
    [void]$lines.Add('|' + (Format-TuiCell $row2 $inner) + '|')
    [void]$lines.Add('+' + ('-' * $inner) + '+')

    # ---- body -------------------------------------------------------------
    # Left pane: categories. Right pane: actions + detail.
    # 38% fits the longest category name in either language ("Windows ads &
    # suggestions" / "广告图缓存与壁纸") without truncating it, which matters
    # because a truncated name is the one thing a user cannot infer.
    $leftW  = [Math]::Max(24, [int]($inner * 0.38))
    $rightW = $inner - $leftW - 1
    # A frame must be exactly as tall as the terminal, no taller: one extra row
    # makes the alternate screen buffer scroll on every repaint, which reads as
    # the whole interface jumping. The fixed rows are the header (rule + two rows
    # + rule = 4), the two body rules, the key line, the status line and the
    # footer rule = 9.
    $bodyH  = $h - 9
    if ($bodyH -lt 6) { $bodyH = 6 }

    # Border rows for the body. The two-pane view needs a junction in the middle
    # to meet the vertical divider; the help page spans the full width, so it gets
    # a plain rule instead of a stray '+' floating in the middle of the border.
    $bodyRule = if ($State.Mode -eq 'help') { '+' + ('-' * $inner) + '+' }
                else { '+' + ('-' * $leftW) + '+' + ('-' * $rightW) + '+' }
    [void]$lines.Add($bodyRule)

    if ($State.Mode -eq 'help') {
        $body = Get-TuiHelpBody -State $State -Width $inner -Height $bodyH
    } else {
        $body = Get-TuiBody -State $State -LeftWidth $leftW -RightWidth $rightW -Height $bodyH
    }
    foreach ($b in $body) { [void]$lines.Add($b) }

    [void]$lines.Add($bodyRule)

    # ---- keys + status ----------------------------------------------------
    $keys = ' ' + (Get-TuiKeyHelp -Language $State.Language -Width $inner)
    [void]$lines.Add('|' + (Format-TuiCell $keys $inner) + '|')
    $msg = $State.Message
    if (-not $msg) {
        $msg = if ($zh) { '空格勾选，p 预览，x 执行；未确认前不会改动任何东西' }
               else     { 'space to toggle, p to preview, x to apply; nothing changes until you confirm' }
    }
    [void]$lines.Add('|' + (Format-TuiCell (' ' + $msg) $inner) + '|')
    [void]$lines.Add('+' + ('-' * $inner) + '+')

    return , $lines.ToArray()
}

function Get-TuiBody {
    <#
      The list pane and the detail pane, already bordered and fitted.
    #>
    [CmdletBinding()]
    param($State, [int]$LeftWidth, [int]$RightWidth, [int]$Height)

    $zh = ($State.Language -eq 'zh')
    $out = New-Object System.Collections.Generic.List[string]

    # ---- left: categories ------------------------------------------------
    $leftLines = New-Object System.Collections.Generic.List[string]
    $top = Get-TuiWindow -Total $State.Groups.Count -Height $Height -Cursor $State.ListIndex
    for ($i = 0; $i -lt $Height; $i++) {
        $gi = $top + $i
        if ($gi -ge $State.Groups.Count) { [void]$leftLines.Add(''); continue }
        $g = $State.Groups[$gi]
        $sel = 0
        foreach ($a in $State.Catalog.actions) {
            if ($a.category -eq $g.id -and $State.Selected.ContainsKey($a.id)) { $sel++ }
        }
        $focus = ($gi -eq $State.ListIndex)
        $mark = ''
        if ($focus) { $mark = if ($State.Pane -eq 'list') { '>' } else { '-' } }
        $line = "{0} {1,3}/{2,-3} {3}" -f $mark, $sel, $g.count, $g.name
        [void]$leftLines.Add($line)
    }

    # ---- right: actions, then a detail block pinned to the bottom ---------
    # The detail block has a fixed height and always occupies the last rows, so
    # neither moving the cursor nor changing category can shift it: the pane has
    # one stable structure instead of a block that floats to wherever the focused
    # action happens to end. Every remaining row belongs to the action list, which
    # is also why the rationale can be given room to wrap rather than be cut off
    # with an ellipsis while blank rows sit underneath it.
    $items = Get-TuiGroupAction $State
    # A taller terminal gives the detail more room, which is what lets a long
    # rationale be shown instead of cut. The height depends only on the terminal
    # size, never on the focused action, so the block still never moves.
    $detailH = [Math]::Min(10, [Math]::Max(6, [int]($Height * 0.33)))
    $detailH = [Math]::Min($detailH, [Math]::Max(1, $Height - 1))
    $listH = [Math]::Max(1, $Height - $detailH)

    $rightLines = New-Object System.Collections.Generic.List[string]
    $dTop = Get-TuiWindow -Total $items.Count -Height $listH -Cursor $State.DetailIndex
    for ($i = 0; $i -lt $listH; $i++) {
        $ai = $dTop + $i
        if ($ai -ge $items.Count) { [void]$rightLines.Add(''); continue }
        $a = $items[$ai]
        $on = $State.Selected.ContainsKey($a.id)
        $box = if ($on) { '[x]' } else { '[ ]' }
        # Same rule as the category pane: the arrow belongs to the pane that has
        # the keyboard, the other pane marks its cursor row quietly.
        $mark = ''
        if ($ai -eq $State.DetailIndex) { $mark = if ($State.Pane -eq 'detail') { '>' } else { '-' } }
        $cur = Get-TuiText -Object $a -Base 'title' -Language $State.Language
        [void]$rightLines.Add(("{0} {1} {2}" -f $mark, $box, $cur))
    }

    # detail block for the focused action
    $detail = New-Object System.Collections.Generic.List[string]
    $cur = Get-TuiActionAt $State
    if ($cur) {
        $riskNames = if ($zh) { @{ low = '低'; medium = '中'; high = '高' } } else { @{ low = 'low'; medium = 'medium'; high = 'high' } }
        $targetLabel = if ($zh) { '触及: ' } else { 'Touches: ' }
        $rows    = [Math]::Max(1, $detailH - 2)          # the separator and the title take two
        $whyRows = [Math]::Max(1, [int][Math]::Ceiling($rows / 2))
        $tgtRows = [Math]::Max(1, $rows - $whyRows)
        [void]$detail.Add('')                            # separator between list and detail
        [void]$detail.Add(("{0}   [{1}]" -f (Get-TuiText -Object $cur -Base 'title' -Language $State.Language), $riskNames[$cur.risk]))
        foreach ($x in (Get-TuiWrap -Text (Get-TuiText -Object $cur -Base 'why' -Language $State.Language) -Width $RightWidth -Max $whyRows)) { [void]$detail.Add($x) }
        foreach ($x in (Get-TuiWrap -Text ("{0}{1}" -f $targetLabel, (Get-TuiTargetLine -Action $cur)) -Width $RightWidth -Max $tgtRows)) { [void]$detail.Add($x) }
    }
    while ($detail.Count -lt $detailH) { [void]$detail.Add('') }
    while ($detail.Count -gt $detailH) { $detail.RemoveAt($detail.Count - 1) }

    # ---- combine, fitting both panes to height ---------------------------
    for ($i = 0; $i -lt $Height; $i++) {
        $l = if ($i -lt $leftLines.Count) { $leftLines[$i] } else { '' }
        if ($i -lt $listH) { $r = if ($i -lt $rightLines.Count) { $rightLines[$i] } else { '' } }
        else               { $r = $detail[$i - $listH] }
        [void]$out.Add('|' + (Format-TuiCell $l $LeftWidth) + '|' + (Format-TuiCell $r $RightWidth) + '|')
    }
    return , $out.ToArray()
}

function Get-TuiHelpBody {
    <#
      The help screen. Same chrome as the main view so switching does not feel
      like a different program.
    #>
    [CmdletBinding()]
    param($State, [int]$Width, [int]$Height)
    $zh = ($State.Language -eq 'zh')
    $rows = if ($zh) {
        @(
            @('上下方向键', '在面板中移动光标'),
            @('Tab',        '在分类面板与动作面板之间切换'),
            @('Enter',      '进入分类；在动作面板中勾选并下移'),
            @('空格',       '勾选 / 取消当前动作'),
            @('1 2 3',      '切换预设 conservative / balanced / aggressive'),
            @('a / n',      '选中 / 取消当前分类全部'),
            @('A / N',      '选中 / 取消全部动作'),
            @('l',          '切换界面语言'),
            @('p',          '预览计划（不修改任何东西）'),
            @('x',          '执行计划（会再次确认并先备份）'),
            @('?',          '显示本帮助'),
            @('q / Esc',    '退出（不会改动任何东西）')
        )
    } else {
        @(
            @('up / down', 'move the cursor within the focused pane'),
            @('Tab',       'switch between the category pane and the action pane'),
            @('Enter',     'enter a category; in the action pane, toggle and move down'),
            @('space',     'toggle the current action'),
            @('1 2 3',     'switch preset: conservative / balanced / aggressive'),
            @('a / n',     'select / clear every action in the current category'),
            @('A / N',     'select / clear every action in the catalog'),
            @('l',         'switch interface language'),
            @('p',         'preview the plan (changes nothing)'),
            @('x',         'apply the plan (confirms again, backs up first)'),
            @('?',         'show this help'),
            @('q / Esc',   'quit without changing anything')
        )
    }
    $out = New-Object System.Collections.Generic.List[string]
    $title = if ($zh) { '按键说明' } else { 'Keyboard' }
    [void]$out.Add(('|' + (Format-TuiCell (' ' + $title) $Width) + '|'))
    $keyW = 14
    foreach ($r in $rows) {
        $line = '  ' + (Format-TuiCell $r[0] $keyW) + $r[1]
        [void]$out.Add('|' + (Format-TuiCell $line $Width) + '|')
    }
    while ($out.Count -lt $Height) { [void]$out.Add('|' + (' ' * $Width) + '|') }
    return , $out.ToArray()
}

function Format-TuiFrame {
    <#
      Wrap a frame in the escape sequences that put it on screen: home the cursor,
      write the whole frame in one call, hide the cursor while drawing.
    #>
    [CmdletBinding()]
    param([string[]]$Lines)
    $esc = $script:Esc
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.Append("$esc[?25l")      # hide cursor
    [void]$sb.Append("$esc[H")         # home
    foreach ($l in $Lines) { [void]$sb.Append($l); [void]$sb.Append("$esc[K`r`n") }
    [void]$sb.Append("$esc[?25h")      # show cursor
    return $sb.ToString()
}
