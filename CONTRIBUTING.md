# Contributing to WinCleanKit

Thanks for helping. Most contributions are a small edit to one JSON file, so this is short.

## The one rule

**The catalog is the single source of truth.** If a behaviour is not described by an action in [`catalog/catalog.json`](catalog/catalog.json), it does not belong in this project. Do not add special cases to the engine or the `.bat` — add data.

## Setup

There is nothing to build.

```powershell
git clone https://github.com/ChanceFlow/WinCleanKit.git
cd WinCleanKit
.\tests\Test-Catalog.ps1     # static: catalog, safety invariants, encoding
.\tests\Test-Engine.ps1      # behavioural: preview/selection semantics
```

Both are read-only. Neither needs administrator rights. On a non-Windows machine the static checks are the useful subset; the engine tests invoke PowerShell.

## Adding an action

Append an object to `actions` in `catalog/catalog.json`.

### Required on every action

| Field | Notes |
|---|---|
| `id` | `category.something-specific`. Stable forever — it is what users type in `-Only` and what restore logs reference. Never rename an existing id; add a new one. |
| `category` | Must match a `categories[].id`. |
| `target` | `registry` · `service` · `task` · `appx` · `path-clean` · `onedrive` |
| `risk` | `low` · `medium` · `high` — see below. |
| `title` / `title_zh` | Imperative and specific. "Disable X", not "Optimise X". |
| `why` / `why_zh` | **One sentence saying what it does and what it costs.** This is the user's only basis for deciding. A weak `why` is a broken action. |
| `presets` | Array from `conservative`, `balanced`, `aggressive`. |

### Risk levels

| Level | Use it when |
|---|---|
| `low` | The change is a preference or stops a background collector, with no visible behaviour change. |
| `medium` | Something visible changes, a convenience feature stops working, or cached content is deleted. Say what in `why`. |
| `high` | A program is removed or a capability is blocked. |

### Target-specific fields

```jsonc
// registry
{ "hive": "HKCU|HKLM", "key": "Software\\...", "name": "ValueName", "type": "DWord|String", "value": 0 }

// service
{ "name": "DiagTrack", "startType": "Disabled|Manual|Automatic" }

// task
{ "path": "\\Microsoft\\Windows\\SomeFolder\\", "name": "TaskName" }

// appx
{ "name": "Microsoft.Something" }

// path-clean
{ "paths": ["%LOCALAPPDATA%\\Some\\Cache"] }
```

### Hard requirements

The test suite rejects a pull request that breaks any of these:

1. `id` values are unique.
2. Every `category` reference resolves.
3. Every action has both languages and at least one preset.
4. `conservative ⊆ balanced ⊆ aggressive`. If you add an action to a small preset, it must also be in every larger one.
5. No action targets the `hosts` file.
6. No action disables an update or core diagnostic service (`wuauserv`, `UsoSvc`, `BITS`, `DoSvc`, `DPS`).
7. No action deletes `TranscodedWallpaper` or the wallpaper cache.

Requirement 6 and 7 exist because breaking Windows Update or a user's wallpaper is not a de-bloat; it is a bug. If you believe an exception is warranted, make the case in the pull request and we will discuss the invariant itself.

## Changing the engine

The engine has one job: execute the catalog and record what it did. Useful invariants to preserve:

- **Preview is the default.** No change happens without `-Apply`.
- **`-Only` is authoritative.** When it is present, the preset is a label. Making it additive breaks per-item deselection in the UI.
- **A dry run touches nothing on disk** — no log directory, no backup folder.
- **Every write is verified by reading back.** Some Windows keys accept and silently drop a write; those must be reported, not assumed successful.
- **Never force ownership of a protected key.** Report the refusal.

If you add a target type, add: a validator branch in `tests/Test-Catalog.ps1`, an executor in the engine, a restore branch in the generated restore script, and a row in `docs/USAGE.md`.

## Editing the `.bat`

Two encoding rules, both enforced by the test suite because getting them wrong produces silent breakage:

- **`.bat` must be UTF-8 *without* BOM and use CRLF.** A BOM prints as garbage before `@echo off`; LF-only confuses `cmd`.
- **`.ps1` must be UTF-8 *with* BOM.** Windows PowerShell 5.1 decodes BOM-less scripts using the ANSI codepage, which turns Chinese strings into mojibake.

`.gitattributes` keeps these bytes stable. Do not let an editor "fix" them.

## Documentation

`docs/CATALOG.md` is **generated** from the catalog. Do not edit it by hand; regenerate it if you add actions. The READMEs describe behaviour and should be updated when behaviour changes.

## Commits and pull requests

- One logical change per pull request.
- Write the commit subject as an imperative sentence: `Add action to disable location services`.
- Say which Windows build you tested on, and what you observed.
- If your change alters what a preset does, call it out — that affects users who never read the changelog.

## Reporting a bug

Include: Windows edition and build (`winver`), the exact command or menu path, the action id, and the relevant lines from `run.log`. If an action silently did nothing, include the registry key or service name so it can be checked directly.

Security-sensitive issues go to [SECURITY.md](SECURITY.md) instead.

## Code of conduct

Participation is covered by [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md). Be decent to each other.
