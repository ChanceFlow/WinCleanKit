<#
.SYNOPSIS
    Regenerates docs/CATALOG.md from catalog/catalog.json.

.DESCRIPTION
    docs/CATALOG.md is a generated file. Editing it by hand means the next
    regeneration silently reverts your change, so the generator lives in the
    repository and the header of the generated file says so.

    The output is bilingual: every action appears once with its English and Chinese
    title and rationale side by side, rather than in two separate documents that
    would inevitably drift apart.

.PARAMETER Check
    Do not write. Exit 1 if docs/CATALOG.md is out of date, which is what CI uses
    to catch a catalog edit that forgot to regenerate the documentation.

.EXAMPLE
    .\tools\New-CatalogDoc.ps1

.EXAMPLE
    .\tools\New-CatalogDoc.ps1 -Check
#>
[CmdletBinding()]
param([switch]$Check)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$catalogPath = Join-Path $root 'catalog/catalog.json'
$outPath = Join-Path $root 'docs/CATALOG.md'

if (-not (Test-Path $catalogPath)) { throw "catalog not found: $catalogPath" }
$cat = Get-Content $catalogPath -Raw -Encoding UTF8 | ConvertFrom-Json

$riskLabel = @{
    low    = '🟢 low / 低'
    medium = '🟡 medium / 中'
    high   = '🔴 high / 高'
}
$presetDesc = @{
    conservative = 'only the lowest-trade-off options / 仅取舍最小的项目'
    balanced     = 'conservative plus everything above / 上一档全部'
    aggressive   = 'balanced plus everything above (all actions) / 上一档全部（即全部动作）'
}

$L = New-Object System.Collections.Generic.List[string]
function Add-Line([string]$Text = '') { [void]$L.Add($Text) }

Add-Line '<!-- GENERATED FILE - do not edit by hand.'
Add-Line '     Regenerate with:  pwsh -File tools/New-CatalogDoc.ps1'
Add-Line '     CI verifies this file is current (tools/New-CatalogDoc.ps1 -Check). -->'
Add-Line ''
# The catalog is bilingual in one file (every action carries both languages), so the
# language switcher points here rather than at a duplicate document that would drift.
Add-Line '[English](CATALOG.md) · [中文](CATALOG.zh-CN.md) · [README](../README.md) · [中文说明](../README.zh-CN.md)'
Add-Line ''
Add-Line '# Action catalog'
Add-Line ''
Add-Line ('**{0} actions across {1} categories.** Generated from [`catalog/catalog.json`](../catalog/catalog.json).' -f $cat.actions.Count, $cat.categories.Count)
Add-Line ''
Add-Line 'Every action appears below with its English and Chinese text, its risk level, and the'
Add-Line 'preset(s) it belongs to. The containment chain `conservative ⊆ balanced ⊆ aggressive` is'
Add-Line 'enforced by `tests/Test-Catalog.ps1`, so a smaller preset never contains something a larger'
Add-Line 'one does not.'
Add-Line ''
Add-Line '## Risk levels'
Add-Line ''
Add-Line '| Level | Meaning |'
Add-Line '|---|---|'
Add-Line '| 🟢 **low / 低** | Reversible preference or a background collector that stops, with no visible change to daily use. |'
Add-Line '| 🟡 **medium / 中** | A visible trade-off: a UI element disappears, a convenience feature stops working, or cached content is deleted. |'
Add-Line '| 🔴 **high / 高** | Removes a program or blocks a capability. Always opt-in, never in a smaller preset. |'
Add-Line ''
Add-Line '## Presets'
Add-Line ''
Add-Line '| Preset | Actions | Contains |'
Add-Line '|---|---|---|'
foreach ($p in 'conservative', 'balanced', 'aggressive') {
    $n = @($cat.actions | Where-Object { $_.presets -contains $p }).Count
    Add-Line ('| `{0}` | {1} | {2} |' -f $p, $n, $presetDesc[$p])
}
Add-Line ''

foreach ($c in $cat.categories) {
    $acts = @($cat.actions | Where-Object { $_.category -eq $c.id })
    Add-Line ('## {0} — {1}' -f $c.name, $c.name_zh)
    Add-Line ''
    Add-Line ('`{0}` · {1} actions' -f $c.id, $acts.Count)
    Add-Line ''
    Add-Line $c.description
    Add-Line ''
    Add-Line $c.description_zh
    Add-Line ''
    foreach ($a in $acts) {
        Add-Line ('### `{0}` — {1}' -f $a.id, $a.title)
        Add-Line ''
        Add-Line ('**{0}**' -f $a.title_zh)
        Add-Line ''
        $presets = ($a.presets | ForEach-Object { '`' + $_ + '`' }) -join ', '
        Add-Line ('- **Risk / 风险:** {0}  ·  **Target / 类型:** `{1}`  ·  **Presets:** {2}' -f $riskLabel[$a.risk], $a.target, $presets)
        Add-Line ('- **Why / 为什么:** {0}' -f $a.why)
        Add-Line ('- **代价 / Cost:** {0}' -f $a.why_zh)

        switch ($a.target) {
            'registry' { Add-Line ('- **Sets:** `{0}\{1}\{2}` = `{3}` ({4})' -f $a.hive, $a.key, $a.name, $a.value, $a.type) }
            'service'  { Add-Line ('- **Sets:** service `{0}` start type to `{1}`' -f $a.name, $a.startType) }
            'task'     { Add-Line ('- **Disables:** scheduled task `{0}{1}`' -f $a.path, $a.name) }
            'appx'     { Add-Line ('- **Uninstalls:** `{0}` and revokes its provisioning' -f $a.name) }
            'path-clean' {
                Add-Line '- **Deletes cached files in:**'
                foreach ($p in $a.paths) { Add-Line ('  - `{0}`' -f $p) }
            }
            'onedrive' { Add-Line '- **Removes:** the OneDrive client binaries and blocks reinstall. The data folder is never touched.' }
        }
        Add-Line ''
    }
}

Add-Line '---'
Add-Line ''
Add-Line '[English](CATALOG.md) · [中文](CATALOG.zh-CN.md) · [README](../README.md) · [中文说明](../README.zh-CN.md)'
Add-Line ''
Add-Line 'Generated from `catalog/catalog.json` by `tools/New-CatalogDoc.ps1`. Do not edit by hand.'
Add-Line ''

# LF, not CRLF: .gitattributes normalises *.md to LF, so a CRLF file would differ
# from the committed content on a fresh checkout and -Check would fail in CI.
$content = ($L -join "`n") + "`n"

if ($Check) {
    $existing = if (Test-Path $outPath) { [IO.File]::ReadAllText($outPath) } else { '' }
    if ($existing -ne $content) {
        Write-Host 'docs/CATALOG.md is out of date. Run: pwsh -File tools/New-CatalogDoc.ps1' -ForegroundColor Red
        exit 1
    }
    Write-Host 'docs/CATALOG.md is current.' -ForegroundColor Green
    exit 0
}

# UTF-8 with BOM: the file contains Chinese and Windows PowerShell 5.1 needs it.
[IO.File]::WriteAllText($outPath, $content, (New-Object Text.UTF8Encoding($true)))
Write-Host ('wrote {0} ({1} lines)' -f $outPath, $L.Count)

# The catalog is bilingual within one file, so the Chinese counterpart is a pointer
# rather than a second copy of 74 actions that would drift out of sync. It is
# generated from here so the two can never disagree about the action count.
$zhPointerPath = Join-Path $root 'docs/CATALOG.zh-CN.md'
$zh = New-Object System.Collections.Generic.List[string]
[void]$zh.Add('[English](CATALOG.md) · [中文](CATALOG.zh-CN.md) · [README](../README.md) · [中文说明](../README.zh-CN.md) · **文档：** [用法](USAGE.zh-CN.md) · [安全](SAFETY.zh-CN.md) · [限制](LIMITATIONS.zh-CN.md) · [代码规范](LINTING.md)')
[void]$zh.Add('')
[void]$zh.Add('# 行动目录')
[void]$zh.Add('')
[void]$zh.Add(('本项目的 {0} 条操作分布在 {1} 个分类中，完整清单见 **[CATALOG.md](CATALOG.md)**。' -f $cat.actions.Count, $cat.categories.Count))
[void]$zh.Add('')
[void]$zh.Add('那份目录**本身就是双语的**：每条操作都同时给出中文与英文的标题、说明与代价，以及风险等级和所属预设，因此不需要、也不应该再维护第二份副本 —— 两份文档必然会逐渐不一致。')
[void]$zh.Add('')
[void]$zh.Add('如果你在找某个具体动作，直接看 [CATALOG.md](CATALOG.md)；想按分类和风险快速浏览，[README.zh-CN.md](../README.zh-CN.md) 里有汇总表。')
[void]$zh.Add('')
[void]$zh.Add('---')
[void]$zh.Add('')
[void]$zh.Add('[English](CATALOG.md) · [中文](CATALOG.zh-CN.md) · [Back to README](../README.md) · [返回中文说明](../README.zh-CN.md)')
[void]$zh.Add('')
[void]$zh.Add('本页由 `tools/New-CatalogDoc.ps1` 生成。请勿手工编辑。')
[void]$zh.Add('')
$zhContent = ($zh -join "`n") + "`n"

if ($Check) {
    if (-not (Test-Path $zhPointerPath) -or [IO.File]::ReadAllText($zhPointerPath) -ne $zhContent) {
        Write-Host 'docs/CATALOG.zh-CN.md is out of date. Run: pwsh -File tools/New-CatalogDoc.ps1' -ForegroundColor Red
        exit 1
    }
    exit 0
}
[IO.File]::WriteAllText($zhPointerPath, $zhContent, (New-Object Text.UTF8Encoding($true)))
Write-Host ('wrote {0} ({1} lines)' -f $zhPointerPath, $zh.Count)
