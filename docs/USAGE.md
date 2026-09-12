# Usage

Everything the `.bat` menu does can be done from the command line, and the command line can do more. This is the same engine either way.

```text
src/WinCleanKit.ps1 [options]
```

Run it from an **elevated** PowerShell for machine-level (`HKLM`) changes. Read-only and user-level actions work unelevated, but a partial run is rarely what you want.

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
| `-Preset conservative\|balanced\|aggressive` | Starting point. Default `balanced`. |
| `-Only <ids or categories>` | **Authoritative** selection. Accepts category ids, exact action ids, `prefix.*`, and comma-separated bundles. |
| `-Skip <ids or categories>` | Remove from whatever the preset or `-Only` selected. Always wins. |
| `-FromFile <path>` | One action id per line. Blank lines and `#` comments are ignored. Merged into `-Only`. |

The rule that matters: **when `-Only` is present, the preset is only a label.** The selection is exactly what you listed. This is what makes deselecting a single item reliable — otherwise the preset would silently add it back.

```powershell
# A whole category
.\src\WinCleanKit.ps1 -Apply -NoPrompt -Only telemetry

# A subset of the ads rules
.\src\WinCleanKit.ps1 -Apply -NoPrompt -Only 'ads'

# Exact ids, mixed with a wildcard
.\src\WinCleanKit.ps1 -Apply -NoPrompt -Only 'ads.cdm.silent-install,apps.maps,privacy.*'

# Start from a preset but drop what you disagree with
.\src\WinCleanKit.ps1 -Apply -NoPrompt -Preset aggressive -Skip 'apps.xbox,apps.outlook-new,onedrive.uninstall'

# Hand-picked list
.\src\WinCleanKit.ps1 -Apply -NoPrompt -FromFile .\my-selection.txt
```

---

## Other options

| Option | Meaning |
|---|---|
| `-Language en\|zh` | Display language. Default `en`. The catalog carries both. |
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
.\src\WinCleanKit.ps1 -Plan -Preset conservative -Language zh

# Unattended on a fresh machine
.\src\WinCleanKit.ps1 -Apply -NoPrompt -Preset balanced

# CI / fleet use: fail loudly and keep the backup path
$r = .\src\WinCleanKit.ps1 -Apply -NoPrompt -Preset balanced -Skip 'apps.todos' -EmitJson | ConvertFrom-Json
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
[low ] Disable DiagTrack service                      <- risk level
  [ OK ] DiagTrack service — Disabled -> Disabled      <- applied
  [skip ] Media Player — not installed                 <- nothing to do
 [WARN] Settings home — key accepted the write but dropped it   <- protected key
 [FAIL] Something — access denied                      <- real failure
```

`[WARN]`/`[FAIL]` on protected keys is expected on some Windows builds. Windows protects a handful of keys and tasks against modification even for administrators; the engine reports that honestly rather than pretending it worked.

---

## Adding your own actions

Everything is data. To add an action, edit [`catalog/catalog.json`](../catalog/catalog.json) and run `tests/Test-Catalog.ps1`. See [CONTRIBUTING.md](../CONTRIBUTING.md) for the schema and the preset rules.
