# WinCleanKit

**A user-first Windows 11 de-bloater.** Close Microsoft's ads and telemetry, remove the apps you never asked for — and stay in control of every single change.

```
  ====================================================================
    WinCleanKit   Windows 11 广告 / 遥测 / 预装清理
  ====================================================================
     Current plan: 45 actions, highest risk [low]   (+0 manual / -0 manual)

     1. Choose a preset       (conservative / balanced / aggressive)
     2. Pick by category      (toggle a whole category)
     3. Customise every item  (flip individual actions on and off)
     4. Preview the plan      (changes nothing)
     5. Apply                 (confirms again, backs up first)
     6. Restore               (undo from a desktop restore point)
     7. Switch language       (en / zh)
     8. About
     0. Quit
```

**English** · [中文说明](README.zh-CN.md) · [Action catalog](docs/CATALOG.md) · [Usage](docs/USAGE.md) · [Safety](docs/SAFETY.md) · [Limitations](docs/LIMITATIONS.md)

---

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

1. Download or clone this repository.
2. Double-click **`src\WinCleanKit.bat`**.
3. Accept the elevation prompt (machine-level changes need administrator rights).
4. Pick a preset, look at the plan, then apply.

That is the whole workflow. Nothing happens until you type `APPLY` at the final confirmation.

> **Requirements:** Windows 10 1809+ or Windows 11 · Windows PowerShell 5.1 or PowerShell 7+ · administrator rights for `HKLM` changes.
> Windows 11 Pro/Home will still send *Required* diagnostic data even after this tool runs — that is a platform limit, not a setting. See [docs/LIMITATIONS.md](docs/LIMITATIONS.md).

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
├── src/
│   ├── WinCleanKit.bat          interactive front-end: elevation, menus, confirmation
│   ├── WinCleanKit.ps1          the engine: resolve -> preview -> apply -> record
│   └── menu/menu.ps1            menu data provider (keeps batch free of JSON parsing)
├── catalog/catalog.json         all 74 actions as data
├── docs/                        catalog reference, usage, safety, limitations, linting
├── tests/                       parse, lint, catalog and engine gates
├── .github/workflows/           CI
└── localization/                UI strings
```

### Design notes

- **The catalog is the single source of truth.** The UI renders it, the engine executes it, the tests validate it. No action exists in code that is not in the catalog.
- **The `.bat` never touches the registry.** It resolves intent and delegates. That is why the UI stays readable and the engine stays testable.
- **`.ps1` files carry a UTF-8 BOM on purpose.** Windows PowerShell 5.1 decodes BOM-less scripts using the ANSI codepage, which turns Chinese UI strings into mojibake. `.gitattributes` marks them `-text` so nothing rewrites their bytes.
- **Writes are verified by reading back.** A few Windows keys accept a write and silently drop it; those are reported as `[FAIL]` instead of a false success.

---

## Contributing

Adding an action is usually a small JSON change. Please read [CONTRIBUTING.md](CONTRIBUTING.md) first — it explains the risk levels, the preset rules, and what a good `why` string looks like.

```powershell
# Syntax gate: the PowerShell parser plus the file-encoding rules
.\tests\Test-Parse.ps1

# Lint gate: PSScriptAnalyzer (needs Install-Module PSScriptAnalyzer -Scope CurrentUser)
.\tests\Test-Analyzer.ps1

# Data integrity, safety invariants, behaviour
.\tests\Test-Catalog.ps1
.\tests\Test-Engine.ps1
```

All four gates also run in CI. Current state: parser clean, PSScriptAnalyzer
`0 errors / 0 warnings`, catalog 31 checks, engine 23 checks. See
[LINTING.md](docs/LINTING.md).

---

## License

[MIT](LICENSE). Use it, fork it, ship it. No warranty — it changes system settings, so read what you select.
