# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **A terminal design system.** The engine now owns one palette and one status
  vocabulary instead of scattering colours and markers through the output:
  - Semantic colour roles (`brand`, `accent`, `success`, `caution`, `danger`,
    `muted`) in a single `$script:Ink` table; `src/WinCleanKit.bat` mirrors the
    same roles so the front-end and the engine read as one product.
  - **Width-aware alignment.** `Format-Text` measures display width, so CJK
    tables line up instead of drifting — PowerShell's own `{0,-20}` counts
    characters, and a Chinese glyph is two columns wide but one character.
  - **Colour is never the only signal.** Every state carries a text marker
    (`[ok]`, `[dry]`, `[--]`, `[!!]`, `[XX]`) and colours degrade to plain text
    when output is redirected, piped, or `NO_COLOR` is set.
  - **Progress for long runs** (`[ 12/74]  16%`), so a 74-action run never looks
    frozen.
  - **A unified status vocabulary**, replacing the previous mix of `[ OK ]`,
    `[skip ]` and `[would]`.
- **`run.bat`**, a double-click launcher at the repository root, so the obvious
  file to open is no longer one hidden under `src\`.
- The generated restore script now uses the same status vocabulary as the engine.

### Changed

- The front-end no longer calls `CLS` on every screen. It repositions the cursor
  and redraws over the previous frame, which removes the flash and keeps the last
  25 lines available as scrollback.
- The front-end header uses the engine's divider style, so the two surfaces match.
- The READMEs lead with what the tool actually looks like — real menu, plan and
  apply output — plus build badges whose numbers are verified against the catalog
  and the gate results.

### Fixed

- PSScriptAnalyzer caught two problems introduced by the refactor: an empty
  `catch` block (now documents why swallowing is correct there) and a
  state-changing verb on a progress helper (`Start-Progress` renamed to
  `Initialize-Progress`).

### Added

- **Bilingual documentation.** `docs/USAGE`, `docs/SAFETY`, `docs/LIMITATIONS`,
  `CONTRIBUTING`, `SECURITY` and `CODE_OF_CONDUCT` now have Chinese counterparts,
  and every bilingual file carries a language switcher that links to its
  counterpart in both directions.
- **`tests/Test-Docs.ps1`** — the documentation gate: every relative link must
  resolve, every translatable document must have a `.zh-CN.md` that links back,
  the switcher must be near the top, and no tracked file may contain a private
  network address.
- **`tools/New-CatalogDoc.ps1`** — the catalog documentation generator, now part of
  the repository instead of a throwaway script. It emits `docs/CATALOG.md` and its
  Chinese pointer, and `-Check` verifies the committed files are current so CI
  catches a catalog edit that forgot to regenerate.
- `docs/CATALOG.md` is now bilingual: each of the 74 actions lists its English and
  Chinese title and rationale together, rather than in two copies that would drift.

### Changed

- The `origin` remote points at the public GitHub URL. The internal Gitea mirror is
  a separate remote named `gitea`, so a clone never reveals an internal address
  through `git remote -v`.

### Notes

- `CONTRIBUTING.md` now documents the bilingual contract, the English-only exceptions
  (with reasons), and the rule against committing internal addresses.

### Added

- **`tests/Test-Parse.ps1`** — the syntax gate. Parses every PowerShell file and
  verifies the file-encoding rules (BOM for `.ps1`/`.psd1`, no BOM and CRLF for `.bat`).
- **`tests/Test-Analyzer.ps1`** — the lint gate, runnable locally and in CI.
- **`docs/LINTING.md`** — why syntax and lint are separate gates, the current finding
  counts, and the reasoning behind each excluded rule.

### Fixed

- **The PowerShell did not previously pass PSScriptAnalyzer.** It had only been
  parser-checked. Running PSScriptAnalyzer 1.25.0 with its full default ruleset found
  106 findings (0 errors, 73 warnings); the actionable ones are now fixed in code.
- `Invoke-OneDriveAction` declared an `$Action` parameter it never used.
- `New-Journal` renamed to `Initialize-Journal`: the `New-` verb asserted a state change
  the function deliberately does not make (a dry run must leave no trace on disk).
- `Emit-Catalog` renamed to `Write-CatalogJson`; the dead `Emit-Plan` helper was deleted.
- `Write-Journal` is no longer called with positional arguments.
- Non-ASCII comments in `.github/PSScriptAnalyzerSettings.psd1` lacked the BOM that
  Windows PowerShell 5.1 needs, which the analyzer's own encoding rule caught.

### Notes

- `[SuppressMessageAttribute]` is only valid inside a function body before `param()`.
  Placing it above a `function` keyword is a parse error, and
  `[CmdletBinding(SupportsShouldProcess)]` is not valid on a function in Windows
  PowerShell 5.1 at all. `Test-Parse.ps1` now catches both classes of mistake.

## [0.1.0] - 2026-09-13

First public release.

### Added

- **Interactive `.bat` front-end** with elevation handling, three presets, per-category
  and per-item selection, a mandatory preview step, and a restore menu.
- **Data-driven engine** (`src/WinCleanKit.ps1`): catalog-driven resolution, preview,
  application and journalling. Usable standalone for scripted and unattended runs.
- **74 actions in 6 categories**: Windows ads and suggestions, telemetry and diagnostic
  data, preinstalled apps, OneDrive, privacy hardening, ad image cache.
- **Three presets** with an enforced containment chain, `conservative ⊆ balanced ⊆ aggressive`
  (45 / 60 / 74 actions).
- **Full rollback**: every run writes `backup.json`, `run.log` and a generated
  `Restore-WinCleanKit.ps1` to a timestamped folder on the Desktop.
- **Bilingual UI** (English / Chinese) with both languages carried inline in the catalog.
- **Command-line interface**: `-Plan`, `-Apply`, `-DryRun`, `-Only`, `-Skip`, `-FromFile`,
  `-Preset`, `-Language`, `-NoPrompt`, `-EmitJson`, `-ListCatalog`, `-ListRestores`, `-Restore`.
- **Test suites**: `tests/Test-Catalog.ps1` (static integrity, safety invariants, encoding)
  and `tests/Test-Engine.ps1` (selection semantics, dry-run purity, bilingual output).
- **Safety invariants enforced by tests**: no `hosts` modification, no disabling of
  Windows Update or core diagnostic services, no touching the wallpaper or its transcode copy.

### Design decisions worth recording

- **`-Only` is authoritative rather than additive.** An additive `-Only` is the obvious
  implementation, but it silently re-adds anything the user deselected in the UI. The
  regression test for this is `deselection survives the round trip`.
- **`New-Journal` does not create its directory.** A dry run must leave no trace on disk.
  Directory creation moved into `Save-Journal`, which a dry run never calls.
- **Wildcard matching requires a wildcard character.** `$Id -like $pattern` treats `.` as a
  wildcard, so an unknown literal id such as `no.such.id` matched every action. Patterns are
  now only treated as globs when they contain `*`, `?` or `[`.
- **`hosts` is out of scope.** A large share of de-bloat guides block Microsoft domains via
  DNS. On managed corporate machines that breaks VPN and SSO (Sangfor aTrust, for example,
  installs its own hosts entries). Services and policies achieve the same reduction with a
  clean rollback path.

[Unreleased]: https://github.com/ChanceFlow/WinCleanKit/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/ChanceFlow/WinCleanKit/releases/tag/v0.1.0
