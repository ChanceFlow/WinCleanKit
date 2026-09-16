<#
.SYNOPSIS
    WinCleanKit TUI - renderer.

.DESCRIPTION
    Turns a state object from Ui.Logic.ps1 into a frame of text lines. This file
    does no drawing and reads no keys: it builds an array of strings and hands it
    back, so the layout can be exercised without a terminal and there is only one
    place that knows about ANSI.

    Frame layout (width x height, minimum 60x18):

        +----------------------------------------------------------------+
        | WinCleanKit  v0.2.0   plan: 45 actions                        |  header
        +--------------------------------+-----------------------------+
        | > 20/22 系统广告与推荐          | [ ] 禁止静默自动安装应用     |  body
        |   21/21 遥测与诊断数据          |                             |
        |   ...                          |                             |
        + 详情 · 分类 -------------------+  (the action list continues) |
        | [分类] 系统广告与推荐   [低]    |                             |
        | 全面关闭 Windows 11 各处的...   |                             |
        +--------------------------------+-----------------------------+
        | up/down move  space toggle  ...                              |  keys
        | [ok] previewed 60 actions                                    |  status
        +----------------------------------------------------------------+

.NOTES
    Part of WinCleanKit. Requires Ui.Logic.ps1 to be loaded first.
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

function Get-TuiKeyHelp {
    [CmdletBinding()]
    param([string]$Language, [int]$Width)
    if ($Language -eq 'zh') {
        $full  = '上下移动  Tab切换面板  Enter进入/勾选  空格勾选  a全选 n全不选  l语言  ?帮助  p预览  x执行  q退出'
        $short = '上下移动  Tab面板  Enter勾选  ?帮助  x执行  q退出'
    } else {
        $full  = 'up/down move  Tab pane  Enter enter/toggle  space toggle  a all  n none  l lang  ? help  p preview  x apply  q quit'
        $short = 'up/down move  Tab pane  Enter toggle  ? help  x apply  q quit'
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
    param($State, [int]$Width, [int]$Height, [string]$Version = '0.2.0')

    $zh = ($State.Language -eq 'zh')
    $w = [Math]::Max(60, $Width)
    $h = [Math]::Max(18, $Height)
    $inner = $w - 2                 # usable width inside the borders
    $lines = New-Object System.Collections.Generic.List[string]

    # The opening language chooser is its own screen: it is shown before there is a
    # language, so it says everything twice rather than picking one.
    if ($State.Mode -eq 'language') {
        return (Get-TuiLanguageFrame -State $State -Width $w -Height $h -Version $Version)
    }

    # ---- header -----------------------------------------------------------
    $title = if ($zh) { 'WinCleanKit' } else { 'WinCleanKit' }
    $planLabel   = if ($zh) { '计划' } else { 'plan' }
    $count = Get-TuiSelectedCount $State
    $planText = "{0}: {1} {2}" -f $planLabel, $count, $(if ($zh) { '项' } else { 'actions' })

    [void]$lines.Add('+' + ('-' * $inner) + '+')
    $row1 = " {0} v{1}   {2}" -f $title, $Version, $planText
    [void]$lines.Add('|' + (Format-TuiCell $row1 $inner) + '|')
    [void]$lines.Add('+' + ('-' * $inner) + '+')

    # ---- body -------------------------------------------------------------
    # Left column: categories on top, the detail panel beneath them. Right column:
    # the action list, and nothing else.
    # The left column carries the wrapping explanatory text now, so it takes a
    # little more than the 38% that only ever had to fit a category name. 42%
    # still fits the longest name in either language together with its counts.
    $leftW  = [Math]::Max(24, [int]($inner * 0.42))
    $rightW = $inner - $leftW - 1
    # A frame must be exactly as tall as the terminal, no taller: one extra row
    # makes the alternate screen buffer scroll on every repaint, which reads as
    # the whole interface jumping. The fixed rows are the header (rule + one row +
    # rule = 3), the two body rules, the key line, the status line and the footer
    # rule = 8.
    $bodyH  = $h - 8
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
      The body of the main view.

      Left column: the category list, with the detail panel beneath it.
      Right column: the action list, and nothing else.

      The right column used to end in a detail block, which meant its shape changed
      with the focused action. It is now a plain list that runs the full height and
      never moves. The detail panel answers "what does this actually do?" for the
      focused action, and sits under the categories where there is room for the
      explanation to wrap instead of being cut.
    #>
    [CmdletBinding()]
    param($State, [int]$LeftWidth, [int]$RightWidth, [int]$Height)

    $zh = ($State.Language -eq 'zh')
    $out = New-Object System.Collections.Generic.List[string]

    # How tall is the detail panel? Proportional and bounded, and a function of the
    # terminal size alone - never of the focused action - so it cannot move.
    $detailH = [Math]::Min(11, [Math]::Max(5, [int]($Height * 0.40)))
    $detailH = [Math]::Min($detailH, [Math]::Max(3, $Height - 4))
    $catH = [Math]::Max(1, $Height - $detailH - 1)

    # ---- left top: categories --------------------------------------------
    $catLines = New-Object System.Collections.Generic.List[string]
    $top = Get-TuiWindow -Total $State.Groups.Count -Height $catH -Cursor $State.ListIndex
    for ($i = 0; $i -lt $catH; $i++) {
        $gi = $top + $i
        if ($gi -ge $State.Groups.Count) { [void]$catLines.Add(''); continue }
        $g = $State.Groups[$gi]
        $sel = 0
        foreach ($a in $State.Catalog.actions) {
            if ($a.category -eq $g.id -and $State.Selected.ContainsKey($a.id)) { $sel++ }
        }
        # Only the pane that has the keyboard draws the focus arrow.
        $mark = ''
        if ($gi -eq $State.ListIndex) { $mark = if ($State.Pane -eq 'list') { '>' } else { '-' } }
        [void]$catLines.Add(("{0} {1,3}/{2,-3} {3}" -f $mark, $sel, $g.count, $g.name))
    }

    # ---- left bottom: the detail panel ------------------------------------
    # Row 0 of this block is the divider itself, carrying the panel label, so the
    # label costs no extra row.
    $isListPane = ($State.Pane -eq 'list')
    $detailLines = New-Object System.Collections.Generic.List[string]
    $label = if ($isListPane) {
        if ($zh) { ' 详情 · 分类 ' } else { ' details · category ' }
    } else {
        if ($zh) { ' 详情 · 条目 ' } else { ' details · action ' }
    }
    $fill = $LeftWidth - (Get-TuiWidth $label)
    [void]$detailLines.Add($label + ('-' * [Math]::Max(0, $fill)))

    $rows = [Math]::Max(2, $detailH - 1)

    if ($isListPane) {
        # When browsing categories on the left: show the focused category's
        # role, scope, selection count, and navigation hint.
        if ($State.ListIndex -lt $State.Groups.Count) {
            $g = $State.Groups[$State.ListIndex]
            $catObj = @($State.Catalog.categories | Where-Object { $_.id -eq $g.id })[0]
            $catName = if ($zh -and $catObj.PSObject.Properties.Name -contains 'name_zh' -and $catObj.name_zh) { $catObj.name_zh } else { $catObj.name }
            $catTitle = if ($zh) { "[分类] {0}" -f $catName } else { "[category] {0}" -f $catName }
            $selCount = 0
            foreach ($a in $State.Catalog.actions) {
                if ($a.category -eq $g.id -and $State.Selected.ContainsKey($a.id)) { $selCount++ }
            }
            $statsLine = if ($zh) {
                "勾选: {0}/{1} 项   提示: Enter/Tab 细选" -f $selCount, $g.count
            } else {
                "Selected: {0}/{1}   Hint: Enter/Tab to inspect" -f $selCount, $g.count
            }
            $catDesc = Get-TuiText -Object $catObj -Base 'description' -Language $State.Language
            [void]$detailLines.Add($catTitle)
            [void]$detailLines.Add($statsLine)
            $descRows = [Math]::Max(1, $rows - 2)
            foreach ($x in (Get-TuiWrap -Text $catDesc -Width $LeftWidth -Max $descRows)) { [void]$detailLines.Add($x) }
        }
    } else {
        # When browsing actions on the right: show the focused action's title,
        # rationale, and the concrete thing it touches.
        $cur = Get-TuiActionAt $State
        if ($cur) {
            $targetLabel = if ($zh) { '触及: ' } else { 'Touches: ' }
            $title = Get-TuiText -Object $cur -Base 'title' -Language $State.Language
            $titleLines = Get-TuiWrap -Text $title -Width $LeftWidth -Max 2

            $rest = [Math]::Max(2, $rows - $titleLines.Count)
            $whyRows = [Math]::Max(1, [int][Math]::Ceiling($rest / 2))
            $tgtRows = [Math]::Max(1, $rest - $whyRows)

            foreach ($x in $titleLines) { [void]$detailLines.Add($x) }
            foreach ($x in (Get-TuiWrap -Text (Get-TuiText -Object $cur -Base 'why' -Language $State.Language) -Width $LeftWidth -Max $whyRows)) { [void]$detailLines.Add($x) }
            foreach ($x in (Get-TuiWrap -Text ("{0}{1}" -f $targetLabel, (Get-TuiTargetLine -Action $cur)) -Width $LeftWidth -Max $tgtRows)) { [void]$detailLines.Add($x) }
        }
    }
    while ($detailLines.Count -lt ($detailH + 1)) { [void]$detailLines.Add('') }
    while ($detailLines.Count -gt ($detailH + 1)) { $detailLines.RemoveAt($detailLines.Count - 1) }

    # ---- right: the action list, and nothing else -------------------------
    $items = Get-TuiGroupAction $State
    $rightLines = New-Object System.Collections.Generic.List[string]
    $dTop = Get-TuiWindow -Total $items.Count -Height $Height -Cursor $State.DetailIndex
    for ($i = 0; $i -lt $Height; $i++) {
        $ai = $dTop + $i
        if ($ai -ge $items.Count) { [void]$rightLines.Add(''); continue }
        $a = $items[$ai]
        $on = $State.Selected.ContainsKey($a.id)
        $box = if ($on) { '[x]' } else { '[ ]' }
        # Same rule as the category list: the arrow belongs to the pane that has
        # the keyboard, the other list marks its cursor row quietly.
        $mark = ''
        if ($ai -eq $State.DetailIndex) { $mark = if ($State.Pane -eq 'detail') { '>' } else { '-' } }
        [void]$rightLines.Add(("{0} {1} {2}" -f $mark, $box, (Get-TuiText -Object $a -Base 'title' -Language $State.Language)))
    }

    # ---- combine, fitting both columns to height --------------------------
    for ($i = 0; $i -lt $Height; $i++) {
        $right = if ($i -lt $rightLines.Count) { $rightLines[$i] } else { '' }
        if ($i -lt $catH) {
            $left = if ($i -lt $catLines.Count) { $catLines[$i] } else { '' }
            [void]$out.Add('|' + (Format-TuiCell $left $LeftWidth) + '|' + (Format-TuiCell $right $RightWidth) + '|')
        } elseif ($i -eq $catH) {
            # The panel divider: the outer border and the vertical divider both
            # become junctions, the way a stacked-panel layout is normally drawn.
            # The action column carries straight on to its right.
            [void]$out.Add('+' + (Format-TuiCell $detailLines[0] $LeftWidth) + '+' + (Format-TuiCell $right $RightWidth) + '|')
        } else {
            [void]$out.Add('|' + (Format-TuiCell $detailLines[$i - $catH] $LeftWidth) + '|' + (Format-TuiCell $right $RightWidth) + '|')
        }
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

function Get-TuiLanguageFrame {
    <#
      The opening language chooser, drawn the same way as every other frame so it
      does not read as a different program: full width, exactly as tall as the
      terminal, every row positioned absolutely when it is painted.

      It is bilingual on purpose. It is shown before a language has been chosen, so
      it cannot use one; saying each line twice also makes it obvious that both
      languages are first class rather than a translation bolted on.
    #>
    [CmdletBinding()]
    param($State, [int]$Width, [int]$Height, [string]$Version = '0.2.0')

    $inner = $Width - 2
    $langs = Get-TuiLanguageList
    $marks = @()
    foreach ($i in 0..($langs.Count - 1)) {
        $marks += $(if ($i -eq $State.LangIndex) { '>' } else { ' ' })
    }

    $content = New-Object System.Collections.Generic.List[string]
    [void]$content.Add('')
    [void]$content.Add(("  WinCleanKit v{0}" -f $Version))
    [void]$content.Add('')
    [void]$content.Add('  请选择界面语言 / Choose your language')
    [void]$content.Add('')
    [void]$content.Add(("  {0} 1. 中文" -f $marks[0]))
    [void]$content.Add(("  {0} 2. English" -f $marks[1]))
    [void]$content.Add('')
    [void]$content.Add('  按 1 或 2、方向键加回车；之后随时可按 l 切换')
    [void]$content.Add('  Press 1 or 2, or arrows and Enter. Press l later to switch.')
    [void]$content.Add('')

    # Never taller than the terminal: that would scroll it before the user has even
    # started. Trim from the end, then centre what is left.
    $room = $Height - 2
    while ($content.Count -gt $room) { $content.RemoveAt($content.Count - 1) }
    $pad = [int](($room - $content.Count) / 2)

    $lines = New-Object System.Collections.Generic.List[string]
    [void]$lines.Add('+' + ('-' * $inner) + '+')
    for ($i = 0; $i -lt $room; $i++) {
        $j = $i - $pad
        $text = if ($j -ge 0 -and $j -lt $content.Count) { $content[$j] } else { '' }
        [void]$lines.Add('|' + (Format-TuiCell $text $inner) + '|')
    }
    [void]$lines.Add('+' + ('-' * $inner) + '+')
    return , $lines.ToArray()
}

function Get-TuiConsoleMode {
    <#
      The console output mode the TUI needs, given the current one.

      Pure, so a test can check the flags without owning a console. Two flags
      matter and both exist to stop the screen from scrolling:

        0x0004 ENABLE_VIRTUAL_TERMINAL_PROCESSING - interpret ANSI escapes
        0x0008 DISABLE_NEWLINE_AUTO_RETURN        - a write that reaches the last
               column must not move to the next row
        0x0002 ENABLE_WRAP_AT_EOL_OUTPUT is cleared for the same reason.

      Terminal.Gui's NetDriver - the driver behind Out-ConsoleGridView - asks
      Windows for exactly this, and pins the screen buffer to the window size on
      top of it. Drawing a full-width row leaves the cursor on the last column
      with the wrap pending; the next thing written then wraps, and a wrap past
      the bottom row scrolls the whole screen. That is what makes an interface
      creep or jump on every keypress.
    #>
    [CmdletBinding()]
    param([uint32]$Current)
    return [uint32](($Current -bor 0x0004 -bor 0x0008) -band 0xFFFFFFFD)
}

function Format-TuiFrame {
    <#
      Put a frame on screen.

      Every row is positioned absolutely and no line feed is ever written, which
      is how Terminal.Gui's NetDriver draws: a newline after the last row - or a
      full-width row reaching the wrap margin - makes the console advance past
      the bottom line, and that advance scrolls the screen. Rows are padded to the
      full width by Get-TuiFrame, so nothing needs erasing and no ESC[K is sent;
      erasing to end of line from the last column would rub out that row's final
      character.
    #>
    [CmdletBinding()]
    param([string[]]$Lines)
    $esc = $script:Esc
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.Append("$esc[?25l")        # hide the cursor while drawing
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        [void]$sb.Append("$esc[$($i + 1);1H")
        [void]$sb.Append($Lines[$i])
    }
    [void]$sb.Append("$esc[?25h")        # show it again
    return $sb.ToString()
}
