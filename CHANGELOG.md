# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
