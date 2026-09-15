# WinCleanKit

**A user-first Windows 11 de-bloater.** Close Microsoft's ads and telemetry, remove the apps you never asked for — and stay in control of every single change.

[![License: MIT](https://img.shields.io/badge/License-MIT-3DA639.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Windows%2010%20%7C%2011-0078D4.svg)](#requirements)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE.svg)](#requirements)
[![Actions](https://img.shields.io/badge/catalog-74%20actions-4B5563.svg)](docs/CATALOG.md)
[![Gates](https://img.shields.io/badge/gates-9%20passing-22C55E.svg)](#repository-layout)

**English** · [中文说明](README.zh-CN.md)  
**Docs / 文档:** [Usage](docs/USAGE.md) ([中文](docs/USAGE.zh-CN.md)) · [Safety](docs/SAFETY.md) ([中文](docs/SAFETY.zh-CN.md)) · [Limitations](docs/LIMITATIONS.md) ([中文](docs/LIMITATIONS.zh-CN.md)) · [Catalog](docs/CATALOG.md) ([中文](docs/CATALOG.zh-CN.md)) · [Linting](docs/LINTING.md)  
**Project / 项目:** [Contributing](CONTRIBUTING.md) ([中文](CONTRIBUTING.zh-CN.md)) · [Security](SECURITY.md) ([中文](SECURITY.zh-CN.md)) · [Code of Conduct](CODE_OF_CONDUCT.md) ([中文](CODE_OF_CONDUCT.zh-CN.md)) · [Changelog](CHANGELOG.md) · [License](LICENSE)

---

## What it looks like

A full-screen TUI, driven entirely by the keyboard. Arrow keys move, `Tab` switches
panes, `space` toggles an action — and the dual-modal detail panel at the bottom-left
answers "what will this actually touch?" and "why does this exist?" before you commit to anything:

```text
+--------------------------------------------------------------------------------------------+
| WinCleanKit v0.1.0   plan: 45 actions                                                      |
+--------------------------------------------------------------------------------------------+
+---------------------------------------+----------------------------------------------------+
|-  20/22  Ads & suggestions            |> [x] Forbid silent app installation                |
|  17/21  Telemetry & diagnostics       | [x] Disable subscribed content (recommendations/ad…|
|   0/19  Preinstalled apps             | [x] Disable Windows Spotlight desktop ad           |
|   0/1   OneDrive                      | [x] Disable lock screen ad overlay                 |
|   7/10  Privacy                       | [ ] Disable lock screen Spotlight rotation         |
|   1/1   Ad cache & wallpaper          | [x] Disable Settings / Start suggestions           |
|                                       | [x] Disable content delivery                       |
|                                       | [x] Disable OEM preinstalled app promotions        |
|                                       | [x] Disable soft landing / welcome pages           |
|                                       | [x] Remove Start menu Recommended section ads      |
+ details · action ---------------------+ [x] Disable recent-file suggestions                |
|Forbid silent app installation         | [x] Hide taskbar Widgets button                    |
|Stops ContentDeliveryManager silently d| [x] Hide taskbar Chat (Teams) button               |
|ownloading and pinning sponsored apps (| [x] Hide desktop 'Learn about this picture' icon   |
|e.g. TikTok, games) into your Start me…| [x] Disable search box web suggestions             |
|Touches: HKCU\Software\Microsoft\Window| [ ] Hide Settings home page promos                 |
|s\CurrentVersion\ContentDeliveryManage…| [x] Disable Edge promotional tabs & recommendations|
|                                       | [x] Disable 'set Edge as default' popup            |
+---------------------------------------+----------------------------------------------------+
| up/down move  Tab pane  Enter toggle  ? help  x apply  q quit                              |
| space to toggle, p to preview, x to apply; nothing changes until you confirm               |
+--------------------------------------------------------------------------------------------+
```

| Key | Action |
|---|---|
| `up` / `down` | Move cursor within the focused pane |
| `Tab` | Switch between category pane (left) and action pane (right) |
| `Enter` | Enter a category; in the action pane, toggle checkbox and step down |
| `space` | Toggle the focused action checkbox |
| `a` / `n` | Select / clear all actions in the focused category |
| `A` / `N` | Select / clear all 74 actions across the entire catalog |
| `l` | Switch interface language (`en` ⇄ `zh`) on the fly |
| `p` | Preview the full execution plan (changes nothing) |
| `x` | Apply the selected plan (creates desktop restore point first) |
| `q` / `Esc` | Quit safely (nothing changes until confirmed) |
| `?` | Show in-app keyboard shortcuts and help |

The TUI does not reimplement anything that keeps you safe. Previewing calls the
engine's own plan renderer, and applying hands the chosen ids back to the engine:

```text
   ------------------------------------------------------------------
   WinCleanKit 0.1.0
   ------------------------------------------------------------------
   Selected : 45 action(s)
   Mode     : PREVIEW ONLY

   Ads & suggestions             20 action(s)
     Forbid silent app installation
     Disable subscribed content (recommendations/ads)
     Disable Windows Spotlight desktop ad
     ...

   Telemetry & diagnostics       17 action(s)
     Set diagnostic data to lowest allowed level
     Set legacy AllowTelemetry to 0
     ...

   Privacy                       7 action(s)
     Disable advertising ID for relevant ads
     ...

   Ad cache & wallpaper          1 action(s)
     Delete Spotlight downloaded ad image cache

   Total actions : 45
```

Applying it — a real-time progress counter, and one status vocabulary where the text marker
carries the meaning, so nothing depends on colour:

```text
   [ok]  [  1/45]   2%  Forbid silent app installation — HKCU\SilentInstalledAppsEnabled = 0
   [--]  [  5/45]  11%  Disable DiagTrack service — not installed
   [!!]  [ 12/45]  26%  Hide Settings home page promos — key accepted the write but dropped it
   [XX]  [ 40/45]  88%  Something — access denied
```

Legend: `[ok]` applied · `[dry]` would apply · `[--]` not applicable · `[!!]` skipped or protected · `[XX]` failed.

> **No console for a full-screen UI?** `run.bat --simple` (or `WinCleanKit.ps1 -Tui:$false`)
> drops into the accessible numbered menu instead. The TUI also detects non-interactive
> or non-ANSI environments automatically and falls back cleanly, rather than spewing
> escape codes into log files.

---

## Why another de-bloater?

Most de-bloat scripts are a wall of `reg add` commands that fire immediately and tell you
afterwards what they did. You have no idea what is about to change, no way to disagree with
any of it, and no clean way back.

WinCleanKit is built the other way round:

| Principle | What it means in practice |
|---|---|
| **You decide** | The safe basics (45 actions) are checked by default; everything else is one toggle away. Nothing runs that you did not select. |
| **You see it first** | Every action carries a plain-language explanation — what it changes, why it is here, and what trade-offs it carries. |
| **You can always go back** | Each run writes a timestamped backup folder plus a self-contained restore script to your Desktop before touching a single setting. |
| **Already-downloaded images are images, not settings** | It cleans ad image caches but strictly refuses to touch or overwrite your personal wallpaper. |
| **Your data is not its business** | It never modifies `hosts`, never touches personal files, and never touches your OneDrive data folder. |
| **No hidden tiers or resets** | Deselecting an item stays deselected; there are no aggressive preset tiers to silently undo your custom choices. |

---

## Quick start

```text
1.  Download or clone this repository
2.  Double-click  run.bat               (or run in terminal)
3.  Choose your language               (opens bilingual chooser; skip with --zh or --en)
4.  Review the plan, toggle checkboxes (space to toggle, Enter to step down)
5.  Press x to apply                   (creates desktop rollback point first)
```

Nothing is written until you confirm the plan, and the first thing a run does is write a
rollback point to your Desktop.

<a id="requirements"></a>
> **Requirements:** Windows 10 1809+ or Windows 11 · Windows PowerShell 5.1 or PowerShell 7+ · administrator rights for machine-level (`HKLM`) changes.
> Windows 11 Pro/Home will still send *Required* diagnostic data even after this tool runs — that is a platform limit, not a setting. See [docs/LIMITATIONS.md](docs/LIMITATIONS.md).

Prefer not to clone? Every [release](https://github.com/ChanceFlow/WinCleanKit/releases) also
ships a packaged download — the tool, its user documentation and the licence, and none of the
test suites, generators or CI definitions. Building it locally is one command:
`tools\New-ReleasePackage.ps1`.

Prefer the command line? `src\WinCleanKit.ps1` is the full engine and accepts all decisions
as flags — see [Command line](#command-line).

### What is on by default

There is no tier to choose before you start. The catalog marks **45 of the 74 actions**
as the default set — the low-trade-off ones, where the worst case is a commercial promotion
or background collector going away — and the interface opens with exactly those checked.
Everything else is opt-in:

| | Actions | What it covers |
|---|---|---|
| **On at start** | 45 | Windows ads and suggestions (20), safe telemetry switches (17), privacy preferences (7), and ad image cache (1). No visible behaviour change beyond ads disappearing. |
| **Opt-in** | 29 | Preinstalled Store apps (19), OneDrive client removal (1), diagnostic error reporting (4), and real trade-off items (3): location, settings sync, text/typing personalization. |

Nothing is ever re-added behind your back. Turning an action off leaves it off, and turning one on
is a single `space` — there is no preset to re-apply that would overwrite your choices. The split
is enforced by `tests/Test-Catalog.ps1`, which also asserts that **nothing that uninstalls software
is on by default**.

---

## Command line

`run.bat` is an elevation and launcher wrapper for `src\WinCleanKit.ps1`. The PowerShell
engine works completely standalone for automation, CI, and scripting.

```powershell
# Show everything the catalog knows, as JSON
.\src\WinCleanKit.ps1 -ListCatalog

# Preview the default selection (changes nothing)
.\src\WinCleanKit.ps1 -Plan

# Preview specific actions with Chinese output
.\src\WinCleanKit.ps1 -Plan -Only 'ads.cdm.silent-install,apps.maps' -Language zh

# Apply a whole category unattended
.\src\WinCleanKit.ps1 -Apply -NoPrompt -Only telemetry

# Apply a hand-picked list from a file (one id per line, '#' comments allowed)
.\src\WinCleanKit.ps1 -Apply -NoPrompt -FromFile .\my-selection.txt

# Apply the default selection minus a few specific items
.\src\WinCleanKit.ps1 -Apply -NoPrompt -Skip 'apps.xbox,apps.outlook-new'

# List and restore from desktop backup points
.\src\WinCleanKit.ps1 -ListRestores
.\src\WinCleanKit.ps1 -Restore WinCleanKit-20260913-004942
```

`-Only` is **authoritative**: when you pass it, the selection is exactly what you asked for
and the default set contributes nothing. This ensures programmatic selection remains completely
predictable.

Full parameter reference: [docs/USAGE.md](docs/USAGE.md).

---

## What it can change

74 actions in 6 categories. **Every single action is data**, defined in
[`catalog/catalog.json`](catalog/catalog.json) — not buried in procedural script code.
Adding, removing or re-wording an action is a JSON edit, and the UI, engine, and docs
pick it up automatically.

| Category | Total | Default | Examples |
|---|---|---|---|
| Windows ads & suggestions | 22 | 20 | Silent app installs, Spotlight lock screen ads, Start recommendations, Widgets feed, Search web suggestions, Edge promo tabs |
| Telemetry & diagnostics | 21 | 17 | `DiagTrack` service, compatibility appraiser, CEIP uploads, feedback prompts |
| Preinstalled apps | 19 | 0 | Clipchamp, Dev Home, Solitaire, Office Hub, Bing News/Weather, Xbox overlay |
| OneDrive | 1 | 0 | Remove OneDrive client and prevent automatic reinstall |
| Privacy hardening | 10 | 7 | Advertising ID, typing personalization, diagnostic tracking, location, settings sync |
| Ad image cache & wallpaper | 1 | 1 | Purge downloaded Spotlight ad image cache |
| **Total** | **74** | **45** | |

Every action documents what it changes, what it touches in registry/services, and its reversibility. Browse the complete catalog in [docs/CATALOG.md](docs/CATALOG.md).

### Deliberately out of scope

WinCleanKit will not do these, by design:

- **Modify your `hosts` file.** Blocking Microsoft domains via DNS breaks Windows Update, Microsoft Store, and corporate VPN/SSO endpoints.
- **Touch personal files, your wallpaper, or your OneDrive data folder.**
- **Disable Windows Update.** Security patches are critical system infrastructure, not bloat.
- **Turn off Delivery Optimization wholesale.** It accelerates local and network updates; peer-to-peer uploading can be toggled without disabling the service.
- **Break Microsoft Edge.** It disables Edge's promotional tabs and popups; it does not excise the browser engine required by WebView2 apps.

---

## Safety and rollback

Before any modification occurs, WinCleanKit generates a standalone rollback package on your Desktop:

```text
Desktop\WinCleanKit-<timestamp>\
├── backup.json                 every original value, byte for byte
├── Restore-WinCleanKit.ps1     one-click undo script for the entire run
└── run.log                     detailed execution log (applied, skipped, failed)
```

To roll back a previous run:

```powershell
powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\Desktop\WinCleanKit-<timestamp>\Restore-WinCleanKit.ps1"
```

Registry keys are restored exactly to their original state, services are reset to their original startup types, and scheduled tasks are re-enabled. Uninstalled Store apps are not silently re-downloaded over the network; the restore script lists the exact packages so you can reinstall them cleanly from the Microsoft Store. Read [docs/SAFETY.md](docs/SAFETY.md) before running on production machines.

---

## Repository layout

```text
WinCleanKit/
├── run.bat                      double-click launcher (what most users need)
├── src/
│   ├── WinCleanKit.bat          interactive front-end: elevation, menus, confirmation
│   ├── WinCleanKit.ps1          the engine + the terminal design system
│   ├── menu/menu.ps1            menu data provider (keeps batch free of JSON parsing)
│   └── lib/                     TUI implementation (logic, renderer, input loop)
├── catalog/catalog.json         all 74 actions as data
├── docs/                        catalog, usage, safety, limitations, linting
├── release/                     front page of the packaged download
├── tests/                       nine gates incl. TUI logic, layout and the package
├── tools/                       New-CatalogDoc.ps1, New-ReleasePackage.ps1
├── .github/workflows/           CI (mirrored in .gitea/workflows)
└── localization/                UI strings
```

### Design notes

- **The catalog is the single source of truth.** The UI renders it, the engine executes it, the tests validate it. No action exists in code that is not in the catalog.
- **The `.bat` never touches the registry.** It resolves intent and delegates. That is why the UI stays readable and the engine stays testable.
- **`.ps1` files carry a UTF-8 BOM on purpose.** Windows PowerShell 5.1 decodes BOM-less scripts using the ANSI codepage, which turns Chinese UI strings into mojibake. `.gitattributes` marks them `-text` so nothing rewrites their bytes.
- **Writes are verified by reading back.** A few Windows keys accept a write and silently drop it; those are reported as `[FAIL]` instead of a false success.

---

#### The terminal design system

The console UI is not ad-hoc `Write-Host` calls. `src/WinCleanKit.ps1` owns one
palette and one status vocabulary, and `src/WinCleanKit.bat` mirrors the same
colour roles, so the front-end and the engine read as one product.

- **Semantic colour roles, not raw colours.** `brand`, `accent`, `success`,
  `caution`, `danger`, `muted`. Changing the palette is one line in `$script:Ink`.
- **Width-aware alignment.** Chinese glyphs occupy two terminal columns but count
  as one character, so PowerShell's own `{0,-20}` leaves CJK tables ragged.
  `Format-Text` measures display width, which is why category counts line up
  identically in English and Chinese.
- **Colour is never the only signal.** Every state has a text marker (`[ok]`,
  `[dry]`, `[--]`, `[!!]`, `[XX]`), and colour degrades to plain text when output
  is redirected, piped, or `NO_COLOR` is set — so logs and CI capture stay clean.
- **Progress for long runs.** A run prints `[ 12/45]  26%`, so it never looks frozen.
- **No flashing.** The front-end repositions the cursor and redraws over the
  previous frame instead of calling `CLS` on every screen, which also keeps the
  last 25 lines as scrollback.

---

## Contributing

Adding an action is usually a small JSON change. Please read [CONTRIBUTING.md](CONTRIBUTING.md) first — it explains the default-selection rule and what a good `why` string looks like.

```powershell
# Syntax gate: the PowerShell parser plus the file-encoding rules
.\tests\Test-Parse.ps1

# Lint gate: PSScriptAnalyzer (needs Install-Module PSScriptAnalyzer -Scope CurrentUser)
.\tests\Test-Analyzer.ps1

# Documentation gate: links resolve, bilingual pairs are complete and cross-linked,
# and no internal addresses leaked into the repository
.\tests\Test-Docs.ps1

# Generated catalog is up to date
.\tools\New-CatalogDoc.ps1 -Check

# Data integrity, safety invariants, behaviour
.\tests\Test-Catalog.ps1
.\tests\Test-Engine.ps1

# TUI: the logic and the layout are pure functions, so they are tested too.
# (The key loop needs a real console and is verified by hand — see Tui.Input.ps1.)
.\tests\Test-Tui.ps1
.\tests\Test-TuiRender.ps1
```

All nine gates run in CI. Current state:
- **Test-Parse.ps1**: 65 checks (PowerShell syntax parser, UTF-8 BOM rules, single-BOM invariant, batch launcher invariants)
- **Test-Analyzer.ps1**: CLEAN (`0 errors / 0 warnings` across PSScriptAnalyzer 1.25.0)
- **Test-Docs.ps1**: 5 checks (238 relative links verified, all bilingual pairs cross-linked, 0 internal network addresses)
- **New-CatalogDoc.ps1 -Check**: generated `docs/CATALOG.md` verified current
- **Test-Catalog.ps1**: 32 checks (schema validity, safety invariants, default-set constraints)
- **Test-Engine.ps1**: 25 checks (selection semantics, dry-run purity, bilingual output)
- **Test-Tui.ps1**: 83 checks (TUI navigation, selection sets, render stamps, language chooser, scroll logic)
- **Test-TuiRender.ps1**: 98 checks (scroll-safe painting contract, frame geometry, dual-modal panels, clean borders)
- **Test-Release.ps1**: 15 checks (the packaged download contains the product, no development file leaked in, the shipped encoding survives, and every link inside the package resolves)

See [LINTING.md](docs/LINTING.md).

---

## License

[MIT](LICENSE). Use it, fork it, ship it. No warranty — it changes system settings, so read what you select.

---

## Documentation conventions

These docs are bilingual. **Every document carries a language switcher at the top, and the
two language versions link to each other** — a one-way link fails CI. A new `X.md` requires
an `X.zh-CN.md`. The full mapping and rules are in
[CONTRIBUTING.md](CONTRIBUTING.md#commits-and-pull-requests).

**Internal addresses are not allowed in this repository** — private IPs, internal
hostnames, or private service ports, in code, docs, commit messages, or a remote URL.
`tests/Test-Docs.ps1` enforces this automatically.
