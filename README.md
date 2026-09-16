# WinCleanKit

**Windows 11's ads, telemetry and bundled apps — switched off, with you deciding what changes.**

[![Latest release](https://img.shields.io/github/v/release/ChanceFlow/WinCleanKit?style=for-the-badge&label=latest%20release)](https://github.com/ChanceFlow/WinCleanKit/releases/latest)
[![Downloads](https://img.shields.io/github/downloads/ChanceFlow/WinCleanKit/total?style=for-the-badge&label=downloads)](https://github.com/ChanceFlow/WinCleanKit/releases)
[![CI](https://github.com/ChanceFlow/WinCleanKit/actions/workflows/ci.yml/badge.svg)](https://github.com/ChanceFlow/WinCleanKit/actions/workflows/ci.yml)
[![Catalog](https://img.shields.io/badge/catalog-74%20actions-4B5563?style=for-the-badge)](docs/CATALOG.md)
[![License: MIT](https://img.shields.io/badge/license-MIT-3DA639?style=for-the-badge)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Windows%2010%20%7C%2011-0078D4?style=for-the-badge)](#download-and-run)

**English** · [中文说明](README.zh-CN.md)  
**Docs / 文档:** [Usage](docs/USAGE.md) ([中文](docs/USAGE.zh-CN.md)) · [Safety](docs/SAFETY.md) ([中文](docs/SAFETY.zh-CN.md)) · [Limitations](docs/LIMITATIONS.md) ([中文](docs/LIMITATIONS.zh-CN.md)) · [Catalog](docs/CATALOG.md) ([中文](docs/CATALOG.zh-CN.md)) · [Linting](docs/LINTING.md)  
**Project / 项目:** [Contributing](CONTRIBUTING.md) ([中文](CONTRIBUTING.zh-CN.md)) · [Security](SECURITY.md) ([中文](SECURITY.zh-CN.md)) · [Code of Conduct](CODE_OF_CONDUCT.md) ([中文](CODE_OF_CONDUCT.zh-CN.md)) · [Changelog](CHANGELOG.md) · [License](LICENSE)

![WinCleanKit running in a Windows console: categories on the left, 74 actions on the right, and a plain-language explanation of the highlighted one](assets/tui-english.png)

An ad in your Start menu. A "suggested" app you never installed. A lock-screen picture that
is quietly selling you something. A widget feed you cannot switch off, a search box that
answers with Bing and MSN. Windows 11 ships with all of it on, and the switches that turn it
off are scattered across a dozen settings screens and registry keys.

WinCleanKit turns it off for you — **but only the parts you tick.** It shows every change in
plain language first, applies nothing without your go-ahead, and writes a restore point to
your Desktop before it touches anything. It is one folder and a `run.bat`: no installer, no
account, no service left running, and no telemetry of its own.

- **You decide.** 45 safe basics are ticked for you; the other 29 are one keypress away. Nothing runs that you did not select, and nothing gets quietly re-added.
- **You see it first.** Each of the 74 actions says what it changes, why it exists and what it touches, before you apply anything.
- **You can always go back.** Every run writes a backup and a one-click restore script to your Desktop first.
- **It stays polite.** No `hosts` file games, no wallpaper changes, no touching your files, no disabling Windows Update, no ripping out Edge.
- **English and Chinese**, switched with one key.

---

## Download and run

1. **[Download the latest release](https://github.com/ChanceFlow/WinCleanKit/releases/latest)** and unzip `WinCleanKit-<version>.zip` anywhere — your Desktop is fine.
2. Double-click **`run.bat`**.
3. Say yes to the Windows prompt. Machine-wide settings need administrator rights.
4. Pick your language, look down the list, tick what you want, then press **`x`** to apply.

Nothing is written to your system until you confirm the plan.

> [!NOTE]
> **Needs:** Windows 10 1809+ or Windows 11, with Windows PowerShell 5.1 or newer — both are
> already on every supported Windows. No installation, no dependencies, nothing to uninstall
> afterwards: delete the folder when you are done.

<details>
<summary><b>Other ways to start it, and how to check the download</b></summary>

**Plain text instead of the full-screen interface** — for old terminals, screen readers, or
if you simply prefer menus:

```bat
run.bat --simple
```

**Skip the language question:** `run.bat --zh` or `run.bat --en`.

**Run it from a clone**, or from the command line:

```powershell
.\src\WinCleanKit.ps1 -Plan                      # preview the default set, change nothing
.\src\WinCleanKit.ps1 -Apply -NoPrompt -Only telemetry
```

**Verify the download** before running it. Every release lists a `.sha256` file next to the
zip:

```powershell
Get-FileHash .\WinCleanKit-0.1.0.zip -Algorithm SHA256
```

**Windows may warn you.** The scripts are not code-signed, so SmartScreen sometimes says
"Windows protected your PC" — that is what it says about any unsigned script you downloaded.
The hash above is how you confirm you got the file we published, and every line of it is
readable in `src/`.

</details>

---

## What it looks like

![The same interface in Chinese](assets/tui-chinese.png)

The whole interface is keyboard-driven, and every key is on the bottom line of the window —
press `?` for the full list. The left column is the areas and their counts; the right column
is the changes themselves; the panel bottom-left explains whatever is highlighted. Nothing
about it needs the mouse, and nothing about it needs reading a manual first.

<details>
<summary><b>Keyboard</b></summary>

| Key | What it does |
|---|---|
| `up` / `down` | Move within the focused pane |
| `Tab` | Switch between the areas and the changes |
| `Enter` | Open an area; in the change list, tick and step down |
| `space` | Tick / untick the highlighted change |
| `a` / `n` | Tick / untick everything in this area |
| `A` / `N` | Tick / untick all 74 |
| `l` | Switch language |
| `p` | Preview the plan without changing anything |
| `x` | Apply the plan (asks once more, writes the restore point first) |
| `?` | Help |
| `q` / `Esc` | Quit |

</details>

---

## What it can change

74 changes in six areas, each one a documented Windows setting, service or app. The count in
brackets is how many are ticked when you open it.

| Area | What is in it |
|---|---|
| **Ads and suggestions** [20/22] | Lock-screen and desktop Spotlight ads, Suggested apps and content in Start, the MSN/Bing feed inside search, "tips and tricks" pop-ups, promotional landing pages after updates, Edge promo tabs and the "set Edge as default" nag. |
| **Telemetry and diagnostics** [17/21] | The diagnostic data level, `DiagTrack`, the compatibility appraiser, the Customer Experience Improvement Program, app-impact telemetry, activity history, advertising ID, feedback requests. |
| **Preinstalled apps** [0/19] | Clipchamp, Dev Home, Solitaire, Office Hub, Bing News and Weather, Maps, Phone Link, Xbox overlay and more — each one you can remove, or leave alone. |
| **OneDrive** [0/1] | Remove the client and stop it reinstalling itself. **Your files are never touched** — uninstalling the app does not delete them. |
| **Privacy** [7/10] | Advertising ID, typing and handwriting personalisation, location, settings sync, tailored experiences. |
| **Ad image cache and wallpaper** [1/1] | Deletes the Spotlight ad images already downloaded. It does not touch the wallpaper you are using. |

**All 74 are listed with their reasons in [docs/CATALOG.md](docs/CATALOG.md)** — and the list is
data (`catalog/catalog.json`), so what you read there is exactly what the tool does.

### What it will not do

- **Nothing that uninstalls software is on by default.** Not one of the 19 apps, not OneDrive. You have to ask.
- **It does not touch your `hosts` file.** Blocking Microsoft there breaks the Store, updates and, on a work laptop, VPN and single sign-on.
- **It does not disable Windows Update**, does not remove Edge, and does not touch your personal files, your wallpaper or your OneDrive folder.
- **It does not turn off Delivery Optimization**, which accelerates updates. The peer-to-peer part is a separate, optional switch.

---

## Is it safe?

**Everything is reversible, and the tool assumes you might want that.** Before the first
change, a run writes a timestamped folder to your Desktop:

```text
Desktop\WinCleanKit-<timestamp>\
├── backup.json                 every original value, byte for byte
├── Restore-WinCleanKit.ps1     one click puts all of it back
└── run.log                     one line per change: applied, skipped, failed
```

Run `Restore-WinCleanKit.ps1` and settings go back exactly, services return to their original
startup type, and disabled tasks are re-enabled. Removed Store apps are listed for you to
reinstall from the Store — that part cannot be undone automatically, which is why it is off
by default.

The one thing worth knowing before you start: **Windows will still send the "Required"
diagnostic data**, on every edition, no matter what any tool does. That floor is built into
the platform; the tool's job is everything above it. That and the other limits are written up
in [docs/LIMITATIONS.md](docs/LIMITATIONS.md).

If it is a work machine, read [docs/SAFETY.md](docs/SAFETY.md) first. It takes two minutes.

---

## Questions

<details>
<summary><b>Do I have to keep it installed?</b></summary>

No. There is nothing to install. Unzip it, run it, delete the folder. Nothing is left
running: no service, no scheduled task, no tray icon.
</details>

<details>
<summary><b>How do I undo everything?</b></summary>

Open the newest `WinCleanKit-<timestamp>` folder on your Desktop and run
`Restore-WinCleanKit.ps1`. Settings, services and tasks go back to exactly what they were.
Only apps you chose to uninstall stay uninstalled — reinstall them from the Microsoft Store.
</details>

<details>
<summary><b>Will it break my PC, my updates or my browser?</b></summary>

It changes documented settings; it does not patch binaries, and it does not block network
traffic. It leaves Windows Update alone, does not remove Edge, and refuses to touch `hosts`.
On a domain-joined or Intune-managed machine, some policies may be re-applied by your
administrator — check [docs/SAFETY.md](docs/SAFETY.md).
</details>

<details>
<summary><b>Do I need administrator rights?</b></summary>

Yes — most of these settings live in machine-wide parts of the registry. The launcher asks for
elevation itself; you click "Yes" once.
</details>

<details>
<summary><b>Does it send anything anywhere?</b></summary>

No. It makes no network calls of its own and has no analytics. You can verify that the easy
way: unplug the network and run it, or read `src/`. It is about 80 KB of readable PowerShell.
</details>

<details>
<summary><b>Can I apply only one or two things?</b></summary>

Yes. In the interface, untick what you do not want — `space` per item, `n` for a whole area,
`N` for everything. For scripts there is `-Only`, `-Skip` and `-FromFile`; see
[docs/USAGE.md](docs/USAGE.md).
</details>

<details>
<summary><b>Why does Windows still phone home afterwards?</b></summary>

Because the "Required" diagnostic level is a floor on every Windows edition, including Pro.
Every tool that claims otherwise is either wrong or is breaking your machine. What we can do
is take everything above that floor out — see [docs/LIMITATIONS.md](docs/LIMITATIONS.md).
</details>

<details>
<summary><b>Is the download the whole repository?</b></summary>

No, deliberately. The release zip contains the tool, its documentation and the licence —
about twenty files. The test suites, the generators and the CI definitions are only in the
repository, for people changing the tool rather than running it.
</details>

---

## Command line

The `.bat` is a launcher; `src\WinCleanKit.ps1` is the engine, and it takes every decision as a
flag, so the same work can run unattended.

```powershell
.\src\WinCleanKit.ps1 -ListCatalog                                # everything it knows, as JSON
.\src\WinCleanKit.ps1 -Plan                                       # preview the default set
.\src\WinCleanKit.ps1 -Plan -Only 'ads.cdm.silent-install,apps.maps' -Language zh
.\src\WinCleanKit.ps1 -Apply -NoPrompt -Only telemetry            # one area, no questions
.\src\WinCleanKit.ps1 -Apply -NoPrompt -FromFile .\my-selection.txt
.\src\WinCleanKit.ps1 -Apply -NoPrompt -Skip 'apps.xbox,apps.outlook-new'
.\src\WinCleanKit.ps1 -ListRestores
.\src\WinCleanKit.ps1 -Restore WinCleanKit-20260913-004942
```

`-Only` is authoritative: the default set contributes nothing when you pass it, so what you
ask for is exactly what runs. Every parameter is documented in
[docs/USAGE.md](docs/USAGE.md).

---

## Contributing

Bug reports, action suggestions and translations are all welcome. Adding a change is usually a
small edit to `catalog/catalog.json` — [CONTRIBUTING.md](CONTRIBUTING.md) explains the rules
and what a good explanation looks like. Please read [SECURITY.md](SECURITY.md) before
reporting anything that looks exploitable, and [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) before
arguing with anyone.

<a id="for-developers"></a>
<details>
<summary><b>For developers and packagers</b></summary>

```text
WinCleanKit/
├── run.bat                      double-click launcher
├── src/
│   ├── WinCleanKit.bat          elevation, menus, confirmation
│   ├── WinCleanKit.ps1          the engine and the terminal design system
│   ├── lib/                     the full-screen UI: logic, renderer, key loop
│   └── menu/menu.ps1            menu data provider
├── catalog/catalog.json         all 74 actions, as data
├── docs/                        usage, safety, limitations, generated catalog
├── release/                     front page of the packaged download
├── tests/                       nine gates
└── tools/                       New-CatalogDoc.ps1, New-ReleasePackage.ps1
```

Nine gates run in CI, on every push, on Windows and Linux:

| Gate | Question it answers |
|---|---|
| `tests/Test-Parse.ps1` | Is this valid PowerShell, with the right file encodings? |
| `tests/Test-Analyzer.ps1` | Does it pass PSScriptAnalyzer? |
| `tests/Test-Docs.ps1` | Do links resolve, are the bilingual pairs complete, did an internal address leak in? |
| `tools/New-CatalogDoc.ps1 -Check` | Is the generated catalog current? |
| `tests/Test-Catalog.ps1` | Is every action complete and safe, and is the default set what we say it is? |
| `tests/Test-Engine.ps1` | Are selection semantics and dry runs what they claim? |
| `tests/Test-Tui.ps1` | Does the UI's logic behave, and does every change force a repaint? |
| `tests/Test-TuiRender.ps1` | Is the frame geometry and the painting contract intact? |
| `tests/Test-Release.ps1` | Does the packaged download contain the product and nothing else? |

`tools/New-ReleasePackage.ps1` builds `dist/WinCleanKit-<version>.zip` from a closed list of
files, and fails the build if a file is in neither list — so nothing new can quietly ship to
users or quietly fail to. Current counts and rule-by-rule reasoning:
[docs/LINTING.md](docs/LINTING.md).

</details>

---

## License

[MIT](LICENSE). Use it, fork it, ship it. No warranty — it changes system settings, so read
what you tick.
