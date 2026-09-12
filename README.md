# WinCleanKit

**A user-first Windows 11 de-bloater.** Close Microsoft's ads and telemetry, remove the apps you never asked for — and stay in control of every single change.

[![License: MIT](https://img.shields.io/badge/License-MIT-3DA639.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Windows%2010%20%7C%2011-0078D4.svg)](#requirements)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE.svg)](#requirements)
[![Actions](https://img.shields.io/badge/catalog-74%20actions-4B5563.svg)](docs/CATALOG.md)
[![Gates](https://img.shields.io/badge/gates-8%20passing-22C55E.svg)](#repository-layout)

**English** · [中文说明](README.zh-CN.md)  
**Docs / 文档:** [Usage](docs/USAGE.md) ([中文](docs/USAGE.zh-CN.md)) · [Safety](docs/SAFETY.md) ([中文](docs/SAFETY.zh-CN.md)) · [Limitations](docs/LIMITATIONS.md) ([中文](docs/LIMITATIONS.zh-CN.md)) · [Catalog](docs/CATALOG.md) ([中文](docs/CATALOG.zh-CN.md)) · [Linting](docs/LINTING.md)  
**Project / 项目:** [Contributing](CONTRIBUTING.md) ([中文](CONTRIBUTING.zh-CN.md)) · [Security](SECURITY.md) ([中文](SECURITY.zh-CN.md)) · [Code of Conduct](CODE_OF_CONDUCT.md) ([中文](CODE_OF_CONDUCT.zh-CN.md)) · [Changelog](CHANGELOG.md) · [License](LICENSE)

---

## What it looks like

A full-screen TUI, driven entirely by the keyboard. Arrow keys move, `Tab` switches
panes, `space` toggles an action — and the right pane answers "what will this
actually touch?" before you commit to anything:

```text
+--------------------------------------------------------------------------------------------+
| WinCleanKit v0.1.0   preset [balanced]   plan: 60 actions                                  |
| highest risk: medium                                                                       |
+--------------------------------------------------------------------------------------------+
+----------------------------------+---------------------------------------------------------+
|-  20/22  Ads & suggestions       |  [x] Forbid silent app installation                     |
|   21/21  Telemetry & diagnostics |  [x] Disable subscribed content (recommendations/ads)   |
|   11/19  Preinstalled apps       |> [x] Disable Windows Spotlight desktop ad               |
|    0/1   OneDrive                |  [x] Disable lock screen ad overlay                     |
|    7/10  Privacy                 |  [ ] Disable lock screen Spotlight rotation             |
|    1/1   Ad cache & wallpaper    |  [x] Disable Settings / Start suggestions               |
|                                  |                                                         |
|                                  |                                                         |
|                                  |Disable Windows Spotlight desktop ad   [low]             |
|                                  |Subscribed content 338389 is the desktop wallpaper/icon …|
|                                  |Touches: HKCU\Software\Microsoft\Windows\CurrentVersion\…|
|                                  |                                                         |
|                                  |                                                         |
|                                  |                                                         |
|                                  |                                                         |
|                                  |                                                         |
+----------------------------------+---------------------------------------------------------+
| up/down move  Tab pane  Enter toggle  1/2/3 preset  ? help  x apply  q quit                |
| space toggles  .  p previews  .  x applies                                                 |
+--------------------------------------------------------------------------------------------+
```

| Key | Action |
|---|---|
| `up` `down` | move within the focused pane |
| `Tab` | switch between the category pane and the action pane |
| `Enter` | open a category; in the action pane, toggle and step down |
| `space` | toggle the current action |
| `1` `2` `3` | preset: conservative / balanced / aggressive |
| `a` / `n` | select / clear every action in the category |
| `A` / `N` | select / clear everything |
| `l` | switch interface language (English / Chinese) |
| `p` / `x` / `q` | preview the plan / apply it / quit |
| `?` | the same help, in-app |

The TUI does not reimplement anything that keeps you safe. Previewing calls the
engine's own plan renderer, and applying hands the chosen ids back to the engine:

```text
   ------------------------------------------------------------------
   WinCleanKit 0.1.0
   ------------------------------------------------------------------
   Preset   : aggressive
   Selected : 74 action(s)
   Mode     : PREVIEW ONLY

   Ads & suggestions         22 action(s)
     [low ] Forbid silent app installation
     [low ] Disable subscribed content (recommendations/ads)
     [MED ] Hide Settings home page promos

   Total actions : 74
   Highest risk  : high
```

Applying it — a progress counter, and one status vocabulary where the text marker
carries the meaning, so nothing depends on colour:

```text
   [ok]  [  1/74]   1%  Forbid silent app installation — HKCU\SilentInstalledAppsEnabled = 0
   [--]  [  5/74]   6%  Uninstall Windows Maps — not installed
   [!!]  [ 12/74]  16%  Hide Settings home page promos — key accepted the write but dropped it
   [XX]  [ 40/74]  54%  Something — access denied
```

Legend: `[ok]` applied · `[dry]` would apply · `[--]` not applicable · `[!!]` skipped or protected · `[XX]` failed.

> **No console for a full-screen UI?** `run.bat --simple` (or
> `WinCleanKit.ps1 -Tui:$false`) gives you the plain numbered menu instead. The TUI
> also detects that situation itself and falls back, rather than painting escape
> codes into a log file.

## Why another de-bloater?

Most de-bloat scripts are a wall of `reg add` commands that fire immediately and tell you afterwards what they did. You have no idea what is about to change, no way to disagree with any of it, and no clean way back.

WinCleanKit is built the other way round:

| Principle | What it means in practice |
|---|---|
| **You decide** | Three presets, then per-category and per-item toggles. Nothing runs that you did not select. |
| **You see it first** | Every action carries a plain-language *why*, a risk level, and a preview step. |
| **You can always go back** | Each run writes a timestamped backup plus a self-contained restore script to your Desktop. |
| **Already-downloaded images are images, not settings** | It deletes ad images but refuses to touch your wallpaper. |
| **Your data is not its business** | It never modifies `hosts`, never touches personal files, and never goes near your OneDrive data folder. |

---

## Quick start

```text
1.  Download or clone this repository
2.  Double-click  run.bat
3.  Accept the elevation prompt        (machine-level changes need admin)
4.  Pick a preset, read the plan, then type APPLY
```

Nothing is written until you type `APPLY` at the final confirmation, and the first
thing a run does is write a rollback point to your Desktop.

<a id="requirements"></a>
> **Requirements:** Windows 10 1809+ or Windows 11 · Windows PowerShell 5.1 or PowerShell 7+ · administrator rights for `HKLM` changes.
> Windows 11 Pro/Home will still send *Required* diagnostic data even after this tool runs — that is a platform limit, not a setting. See [docs/LIMITATIONS.md](docs/LIMITATIONS.md).

Prefer the command line? `src\WinCleanKit.ps1` is the whole engine and takes the same
decisions as flags — see [Command line](#command-line).

### The three presets

| Preset | Actions | What it does | Risk |
|---|---|---|---|
| `conservative` | 45 | Ads, suggestions and the safest telemetry switches. No visible behaviour change beyond the ads disappearing. | low/medium |
| `balanced` | 60 | Everything above, plus error-reporting and compatibility-assistant services, and the clearly unneeded bundled apps. | low/medium |
| `aggressive` | 74 | Everything above, plus items with a real trade-off: Game Bar overlay, OneDrive, location, settings sync, the new Outlook, Phone Link. | up to high |

`conservative ⊂ balanced ⊂ aggressive` is enforced by the test suite, so a smaller preset never contains something a larger one does not.

---

## Command line

The `.bat` is a front-end for `src\WinCleanKit.ps1`. The engine works fine on its own, which makes unattended and scripted use easy.

```powershell
# Show everything the catalog knows, as JSON
.\src\WinCleanKit.ps1 -ListCatalog

# Preview a preset (changes nothing)
.\src\WinCleanKit.ps1 -Plan -Preset balanced

# Preview exactly two actions, in Chinese
.\src\WinCleanKit.ps1 -Plan -Preset conservative -Only 'ads.cdm.silent-install,apps.maps' -Language zh

# Apply a whole category unattended
.\src\WinCleanKit.ps1 -Apply -NoPrompt -Preset aggressive -Only telemetry

# Apply a hand-picked list from a file (one id per line, '#' comments allowed)
.\src\WinCleanKit.ps1 -Apply -NoPrompt -FromFile .\my-selection.txt

# Apply a preset minus a few things you disagree with
.\src\WinCleanKit.ps1 -Apply -NoPrompt -Preset balanced -Skip 'apps.xbox,apps.outlook-new'

# See and use restore points
.\src\WinCleanKit.ps1 -ListRestores
.\src\WinCleanKit.ps1 -Restore WinCleanKit-20260913-004942
```

`-Only` is **authoritative**: when you pass it, the selection is exactly what you asked for. The preset becomes a label. This is what makes per-item deselection work reliably.

Full parameter reference: [docs/USAGE.md](docs/USAGE.md).

---

## What it can change

74 actions in 6 categories. **Every one of them is data**, in [`catalog/catalog.json`](catalog/catalog.json) — not hardcoded logic. Adding, removing or re-wording an action is a JSON edit, and the UI and the engine pick it up automatically.

| Category | Count | Examples |
|---|---|---|
| Windows ads & suggestions | 22 | silent app installation, Spotlight lock-screen ads, Start menu recommendations, widget feed, search box web suggestions, Edge promo tabs |
| Telemetry & diagnostic data | 21 | `DiagTrack`, compatibility appraiser, CEIP uploads, error reporting, feedback prompts |
| Preinstalled apps | 19 | Clipchamp, Dev Home, Solitaire, Office Hub, Bing News/Weather, Xbox overlay |
| OneDrive | 1 | remove the client and block reinstall |
| Privacy hardening | 9 | advertising ID, input personalization, implicit text/ink collection, location, settings sync |
| Ad image cache & wallpaper | 1 | delete downloaded Spotlight ad images |

Every action documents its risk, its trade-off, and why it exists. Browse the whole list in [docs/CATALOG.md](docs/CATALOG.md).

### Deliberately out of scope

WinCleanKit will not do these, by design:

- **Modify your `hosts` file.** Blocking Microsoft domains that way can break Windows Update, the Store, and — on corporate machines — VPN and SSO logins.
- **Touch your personal files, wallpaper, or OneDrive data folder.**
- **Disable Windows Update.** Security patches are not bloat.
- **Turn off Delivery Optimization.** It is an update accelerator, not telemetry. (You can opt out of its peer-to-peer sharing separately.)
- **Break Edge.** It removes Edge's promotional tabs; it does not remove the browser.

---

## Safety and rollback

Before anything is changed, WinCleanKit creates:

```
Desktop\WinCleanKit-<timestamp>\
├── backup.json                 every original value, byte for byte
├── Restore-WinCleanKit.ps1     one-click undo for the whole run
└── run.log                     one line per action, including skips and failures
```

```powershell
powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\Desktop\WinCleanKit-<timestamp>\Restore-WinCleanKit.ps1"
```

Registry values are restored exactly, services go back to their original start type, scheduled tasks are re-enabled. Uninstalled Store apps are not re-downloaded automatically (the restore script tells you which ones to reinstall). Read [docs/SAFETY.md](docs/SAFETY.md) before running it on a work machine.

---

## Repository layout

```
WinCleanKit/
├── run.bat                      double-click launcher (what most users need)
├── src/
│   ├── WinCleanKit.bat          interactive front-end: elevation, menus, confirmation
│   ├── WinCleanKit.ps1          the engine + the terminal design system
│   └── menu/menu.ps1            menu data provider (keeps batch free of JSON parsing)
├── catalog/catalog.json         all 74 actions as data
├── docs/                        catalog, usage, safety, limitations, linting
├── tests/                       eight gates incl. TUI logic and layout
├── tools/                       New-CatalogDoc.ps1 (generates the bilingual catalog)
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
  `Format-Text` measures display width, which is why the category counts line up
  identically in English and Chinese.
- **Colour is never the only signal.** Every state has a text marker (`[ok]`,
  `[dry]`, `[--]`, `[!!]`, `[XX]`), and colour degrades to plain text when output
  is redirected, piped, or `NO_COLOR` is set — so logs and CI capture stay clean.
- **Progress for long runs.** A 74-action run prints `[ 12/74]  16%`, so it never
  looks frozen.
- **No flashing.** The front-end repositions the cursor and redraws over the
  previous frame instead of calling `CLS` on every screen, which also keeps the
  last 25 lines as scrollback.

## Contributing

Adding an action is usually a small JSON change. Please read [CONTRIBUTING.md](CONTRIBUTING.md) first — it explains the risk levels, the preset rules, and what a good `why` string looks like.

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

All eight gates run in CI. Current state: parser 37 checks, PSScriptAnalyzer
`0 errors / 0 warnings`, docs 5 checks (229 links), catalog 31 checks, engine 23
checks, TUI logic 55 checks, TUI layout 50 checks. See [LINTING.md](docs/LINTING.md).

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
