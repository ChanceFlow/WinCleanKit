[English](USAGE.md) · [中文](USAGE.zh-CN.md) · **Docs:** [README](../README.md) · [Usage](USAGE.md) · [Safety](SAFETY.md) · [Limitations](LIMITATIONS.md) · [Catalog](CATALOG.md) · [Linting](LINTING.md)

# Usage

Everything the `.bat` menu does can be done from the command line, and the command line can do more. This is the same engine either way.

```text
src/WinCleanKit.ps1 [options]
```

Run it from an **elevated** PowerShell for machine-level (`HKLM`) changes. Read-only and user-level actions work unelevated, but a partial run is rarely what you want.

---

## Starting it

Double-click `run.bat`, or run `src\WinCleanKit.bat`. Either way it elevates.

`run.bat` asks for the **windowed interface**. `src\WinCleanKit.bat` on its own opens the
full-screen console interface instead, which is what runs when there is no desktop to put a
window on. Each interface reports whether it could start, so the launcher degrades rather than
failing: window, then console, then the numbered menu.

**It opens on a language chooser.** That screen is bilingual on purpose: it is shown
before a language has been picked, so it says each line twice — Chinese first, then
English. Press `1` for Chinese, `2` for English, or use the arrow keys and `Enter`.
You can change your mind at any time with `l` inside the interface.

To skip the chooser, name the language on the command line:

```bat
run.bat --lang zh
run.bat --lang en
run.bat --zh
run.bat --en
```

| Switch | What it does |
|---|---|
| `--lang zh` / `--lang en` | Open in that language, with no chooser. |
| `--lang=zh` / `--lang=en` | The same thing. |
| `--zh` / `--en` | The same thing, spelled short. |
| `--gui` | The windowed interface. `run.bat` passes this for you. |
| `--tui` | Force the full-screen console interface, even when a window is possible. |
| `--simple` / `--no-tui` | The numbered menu instead of either interface, for automation and screen readers. |

An unrecognised value falls back to the chooser rather than guessing.

---

## Modes

| Option | What it does |
|---|---|
| *(none)* | Resolve and preview the plan, then stop. |
| `-Plan` | Same as above, stated explicitly. |
| `-Apply` | Execute the plan. |
| `-Apply -DryRun` | Walk the whole flow, report what would happen, change and create nothing. |
| `-ListCatalog` | Print the catalog as JSON and exit. |
| `-ListRestores` | List restore points on the Desktop. |
| `-Restore <name>` | Run a restore point's script. |
| `-Version` | Print the engine version. |

**Nothing is ever applied without `-Apply`.** `-Plan` is the default so that a typo cannot cause changes.

---

## Choosing what to apply

| Option | Meaning |
|---|---|
| `-Only <ids or categories>` | **Authoritative** selection. Accepts category ids, exact action ids, `prefix.*`, and comma-separated bundles. |
| `-Skip <ids or categories>` | Remove from the default selection, or from `-Only`. Always wins. |
| `-FromFile <path>` | One action id per line. Blank lines and `#` comments are ignored. Merged into `-Only`. |

With no selection option at all, the engine runs the catalog's **default set** — the 45
actions marked `default`, which are the low-trade-off ones: ads and suggestions, the
safest telemetry switches, and the privacy preferences. Everything else is opt-in, and
nothing that uninstalls software is ever on by default.

The rule that matters: **when `-Only` is present, the default set contributes nothing.**
The selection is exactly what you listed. This is what makes deselecting a single item
reliable — otherwise the default set would silently add it back.

```powershell
# A whole category
.\src\WinCleanKit.ps1 -Apply -NoPrompt -Only telemetry

# A subset of the ads rules
.\src\WinCleanKit.ps1 -Apply -NoPrompt -Only 'ads'

# Exact ids, mixed with a wildcard
.\src\WinCleanKit.ps1 -Apply -NoPrompt -Only 'ads.cdm.silent-install,apps.maps,privacy.*'

# Start from the default set but drop what you disagree with
.\src\WinCleanKit.ps1 -Apply -NoPrompt -Skip 'ads.taskbar.widgets-button,telemetry.ceip'

# Hand-picked list
.\src\WinCleanKit.ps1 -Apply -NoPrompt -FromFile .\my-selection.txt
```

---

## Other options

| Option | Meaning |
|---|---|
| `-Language en\|zh` | Display language for the engine's own output. Default `en`. The catalog carries both. |
| `-Gui` | Open the windowed interface. In `src\WinCleanKit.bat` this is `--gui`, and `run.bat` passes it for you. |
| `-Tui` | Open the full-screen console interface. In `src\WinCleanKit.bat` this is `--tui`. |
| `-TuiLanguage en\|zh\|ask` | The language either interactive interface opens in. `ask` — the default — opens the chooser. |
| `-NoPrompt` | Never ask. Required for unattended runs; without it you are asked to type `APPLY`. |
| `-EmitJson` | Print a machine-readable result object on stdout. |

`-EmitJson` shape:

```json
{ "ok": 44, "skipped": 1, "failed": 0, "journal": "C:\\Users\\you\\Desktop\\WinCleanKit-20260913-004942", "failures": [] }
```

---

## Examples

```powershell
# Look before you leap
.\src\WinCleanKit.ps1 -Plan -Language zh

# Unattended on a fresh machine: the default set, no prompting
.\src\WinCleanKit.ps1 -Apply -NoPrompt

# CI / fleet use: fail loudly and keep the backup path
$r = .\src\WinCleanKit.ps1 -Apply -NoPrompt -Skip 'telemetry.ceip' -EmitJson | ConvertFrom-Json
if ($r.failed -gt 0) { throw "debloat had $($r.failed) failures: $($r.failures -join '; ')" }
Write-Host "backup: $($r.journal)"

# Undo the last run
$last = Get-ChildItem "$env:USERPROFILE\Desktop\WinCleanKit-*" -Directory | Sort-Object LastWriteTime -Descending | Select-Object -First 1
.\src\WinCleanKit.ps1 -Restore $last.Name
```

---

## Exit codes

| Code | Meaning |
|---|---|
| `0` | Completed. Individual actions may still have been *skipped* (not applicable or protected) — check `skipped`/`failures`. |
| `1` | The engine aborted (bad catalog, unreadable selection file, unexpected error). |

A `[FAIL]` for a single action does not abort the run; it is recorded as protected/skipped and reported in `failures`.

---

## Reading the output

```
Disable DiagTrack service                            <- what it does
  [ OK ] DiagTrack service — Disabled -> Disabled      <- applied
  [skip ] Media Player — not installed                 <- nothing to do
 [WARN] Settings home — key accepted the write but dropped it   <- protected key
 [FAIL] Something — access denied                      <- real failure
```

`[WARN]`/`[FAIL]` on protected keys is expected on some Windows builds. Windows protects a handful of keys and tasks against modification even for administrators; the engine reports that honestly rather than pretending it worked.

---

## Adding your own actions

Everything is data. To add an action, edit [`catalog/catalog.json`](../catalog/catalog.json) and run `tests/Test-Catalog.ps1`. The schema and the default-selection rule are documented in `CONTRIBUTING.md` in the project repository.
