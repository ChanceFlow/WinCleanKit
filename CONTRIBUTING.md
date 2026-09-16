[English](CONTRIBUTING.md) · [中文](CONTRIBUTING.zh-CN.md) · **Docs:** [README](README.md) · [Usage](docs/USAGE.md) · [Safety](docs/SAFETY.md) · [Limitations](docs/LIMITATIONS.md) · [Catalog](docs/CATALOG.md) · [Linting](docs/LINTING.md)

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
| `title` / `title_zh` | Imperative and specific. "Disable X", not "Optimise X". |
| `why` / `why_zh` | **One sentence saying what it does and what it costs.** This is the user's only basis for deciding. A weak `why` is a broken action. |
| `default` | `true` only for the low-trade-off actions that are selected when the tool starts. Anything that uninstalls software, or carries a visible trade-off, must be `false`. |

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
3. Every action has both languages and a `default` flag.
4. Nothing that uninstalls software is `default: true`.
5. No action targets the `hosts` file.
6. No action disables an update or core diagnostic service (`wuauserv`, `UsoSvc`, `BITS`, `DoSvc`, `DPS`).
7. No action deletes `TranscodedWallpaper` or the wallpaper cache.

Requirement 6 and 7 exist because breaking Windows Update or a user's wallpaper is not a de-bloat; it is a bug. If you believe an exception is warranted, make the case in the pull request and we will discuss the invariant itself.

## Changing the engine

The engine has one job: execute the catalog and record what it did. Useful invariants to preserve:

- **Preview is the default.** No change happens without `-Apply`.
- **`-Only` is authoritative.** When it is present the default set contributes nothing. Making it additive breaks per-item deselection in the UI.
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

**Bilingual documentation is mandatory.** Every document needs a language switcher at
the top, and the two language versions must link to **each other** — a one-way link
fails CI. A new `X.md` requires an `X.zh-CN.md` (and vice versa). The switcher must name
real filenames; a link that points only at the file it lives in is rejected.

| English | Chinese |
|---|---|
| [`README.md`](README.md) | [`README.zh-CN.md`](README.zh-CN.md) |
| [`CONTRIBUTING.md`](CONTRIBUTING.md) | [`CONTRIBUTING.zh-CN.md`](CONTRIBUTING.zh-CN.md) |
| [`SECURITY.md`](SECURITY.md) | [`SECURITY.zh-CN.md`](SECURITY.zh-CN.md) |
| [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md) | [`CODE_OF_CONDUCT.zh-CN.md`](CODE_OF_CONDUCT.zh-CN.md) |
| [`docs/USAGE.md`](docs/USAGE.md) | [`docs/USAGE.zh-CN.md`](docs/USAGE.zh-CN.md) |
| [`docs/SAFETY.md`](docs/SAFETY.md) | [`docs/SAFETY.zh-CN.md`](docs/SAFETY.zh-CN.md) |
| [`docs/LIMITATIONS.md`](docs/LIMITATIONS.md) | [`docs/LIMITATIONS.zh-CN.md`](docs/LIMITATIONS.zh-CN.md) |
| [`docs/CATALOG.md`](docs/CATALOG.md) | [`docs/CATALOG.zh-CN.md`](docs/CATALOG.zh-CN.md) — the catalog itself is bilingual; the Chinese page is a pointer |

English-only by decision (not by omission): [`CHANGELOG.md`](CHANGELOG.md) (a changelog
is a technical log, and per-language copies drift), [`docs/LINTING.md`](docs/LINTING.md)
(contributor-facing), [`localization/README.md`](localization/README.md) (it is about
translations).

**Never commit internal addresses.** No private IPs, internal hostnames, or private
service endpoints in code, docs, commit messages, or a remote URL. `tests/Test-Docs.ps1`
enforces this for tracked files.

`tests/Test-Docs.ps1` checks all of the above: link resolution, pair completeness,
bidirectional linking, switcher placement, and the absence of private addresses.

## How the pieces fit together

- **The catalog is the single source of truth.** `catalog/catalog.json` is the only place an
  action is defined: the UI renders it, the engine executes it, the tests validate it, and
  `tools/New-CatalogDoc.ps1` generates the documentation from it. No action exists in code that
  is not in the catalog.
- **The `.bat` never touches the registry.** It resolves intent and delegates. That is what
  keeps the front-end readable and the engine testable on its own.
- **`.ps1` files carry a UTF-8 BOM on purpose.** Windows PowerShell 5.1 decodes a BOM-less
  script with the machine's ANSI codepage, which turns Chinese strings into mojibake;
  `.gitattributes` marks them `-text` so nothing rewrites their bytes. `Test-Parse.ps1` enforces
  the BOM (and rejects a doubled one).
- **Writes are verified by reading back.** A few Windows keys accept a write and silently drop
  it, so the engine reads the value back and reports `[!!]` rather than claiming success.
- **The release package is built from a closed list.** `tools/New-ReleasePackage.ps1` fails if a
  file is in neither the include nor the exclude list, so nothing new can quietly ship to users
  or quietly fail to.

## The two interactive frontends

`src/lib/Ui.Logic.ps1` is the state machine: navigation, selection, plan assembly, localisation,
and the projections a window needs. It touches no screen API, and both frontends are thin glue
around it — `src/lib/Tui.Render.ps1` + `Tui.Input.ps1` draw it as characters, `src/gui/WinCleanKit.gui.ps1`
draws it as controls. Adding a key or a button means calling the same `Switch-*` / `Move-*`
function, never re-deciding anything in the UI layer.

The window runs the engine as a **child process** with an authoritative `-FromFile` id list,
inside a background runspace whose output a UI timer drains onto the progress bar. That is the
same engine invocation the console interface already makes for a preview; the process boundary
is the only difference, and it is what keeps the window responsive for 74 actions.

**Colour lives in one place.** `$script:GuiPalette` holds a light and a dark set of semantic
roles (`window`, `card`, `text`, `muted`, `border`, `controlBorder`, `brand`, `accent`, `success`,
`caution`, `danger`, `selection`), and layout code asks for a role, never a colour. That is the
same vocabulary the console frontend uses in `$script:Ink`, which is what keeps the two looking
like one product. A hex value outside that table fails the gate, and so does a text pair that
drops below 4.5:1 — the check measures the palette, so a "small tweak" cannot quietly make
something unreadable.

**The window is five pages, and the run button is not on the page where you tick things.**
`WinCleanKit.gui.ps1` builds a navigation rail over five page panels — overview, choose, apply,
restore, about — and `Show-GuiPage` is what switches between them; each rail entry carries its
step's live state. The gate holds you to that shape: `runIt` must not be a child of the page you
select on. Choosing and running are separate steps, and putting them back together fails
`Test-Gui.ps1`.

Four traps worth knowing before you touch that file:

- **A handler runs in its own scope.** Shared state lives in `$script:GuiApp`; a local assignment
  inside an event handler is gone by the next click. Its name avoids every parameter of
  `WinCleanKit.ps1`, because the file is dot-sourced into that script's scope and assigning to a
  variable the engine declared as `[switch]` throws at runtime. `Test-Gui.ps1` checks that.
- **Event arguments are in `$args`, not `$_`.** `$_` is not the event object for an `Add_*`
  handler, and reading `$_.KeyCode` fails at the moment a user presses a key.
- **PowerShell's own read-only variables collide too.** `$home` is a directory, not a place to put
  a panel: the assignment throws `VariableNotWritable` while the window is being built.
  `Test-Gui.ps1` checks every assignment against the reserved names, next to the engine-parameter
  check — that is how `$home` was caught before a user was.
- **A check box drawn as a button measures its own text short.** `Appearance = 'Button'` under
  `AutoSize` painted `Privacy  7/10` as `Privacy 7/` on a real screen, and `&` is a mnemonic in a
  button label, so the catalog's `Ads & suggestions` came out as `Ads suggestions`. `Format-GuiChip`
  sizes itself from `TextRenderer.MeasureText` with `NoPrefix`, and the gate checks both against a
  real control.

`tests/Test-Gui.ps1` covers the projections, the parity between the two frontends, the form
construction (which works without a desktop) and the checkbox path. What it cannot cover is how
the window looks and whether a real mouse click behaves; that is verified by hand in a real
session, the same way the console key loop is.

## The terminal design system

The console output is not ad-hoc `Write-Host` calls. `src/WinCleanKit.ps1` owns one palette and
one status vocabulary, and `src/WinCleanKit.bat` mirrors the same colour roles, so the front-end
and the engine read as one product.

- **Semantic colour roles, not raw colours.** `brand`, `accent`, `success`, `caution`, `danger`,
  `muted`. Changing the palette is one line in `$script:Ink`.
- **Width-aware alignment.** Chinese glyphs occupy two terminal columns but count as one
  character, so PowerShell's own `{0,-20}` leaves CJK tables ragged. `Format-Text` measures
  display width, which is why the counts line up identically in both languages.
- **Colour is never the only signal.** Every state carries a text marker (`[ok]`, `[dry]`,
  `[--]`, `[!!]`, `[XX]`), and colour degrades to plain text when output is redirected, piped,
  or `NO_COLOR` is set -- so logs and CI capture stay clean.
- **Progress for long runs.** A run prints `[ 12/45]  26%`, so it never looks frozen.
- **No flashing.** The front-end repositions the cursor and redraws over the previous frame
  instead of calling `CLS` on every screen, which also keeps the last lines as scrollback.
- **The full-screen UI paints like Terminal.Gui's NetDriver** -- absolute row positioning, no
  line feed, the screen buffer pinned to the window -- because a full-width row plus a line feed
  scrolls the window on every repaint. `tools/Test-TuiScroll.ps1` reads the console buffer back
  in a real window and checks it; see [docs/LIMITATIONS.md](docs/LIMITATIONS.md) for why that one
  check has to be run by hand.

## Commits and pull requests

- One logical change per pull request.
- Write the commit subject as an imperative sentence: `Add action to disable location services`.
- Say which Windows build you tested on, and what you observed.
- If your change alters the `default` set, call it out. That changes what runs for users who never open the catalog.

## Reporting a bug

Include: Windows edition and build (`winver`), the exact command or menu path, the action id, and the relevant lines from `run.log`. If an action silently did nothing, include the registry key or service name so it can be checked directly.

Security-sensitive issues go to [SECURITY.md](SECURITY.md) instead.

## Code of conduct

Participation is covered by [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md). Be decent to each other.
