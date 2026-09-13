# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Dual-modal detail panel and comprehensive catalog descriptions.** The detail
  panel adapts to the active pane: selecting a category on the left presents the
  category's scope, overview, and selection count, while selecting an action on the
  right presents that action's rationale, default membership, and technical target.
  All 74 actions across all 6 categories in `catalog/catalog.json` and `docs/CATALOG.md`
  were expanded with thorough explanations (behavior, debloat rationale, trade-offs/side
  effects, and reversibility), replacing previous terse one-liners.
- **A language chooser as the first screen.** The full-screen interface used to open
  in English unconditionally, which is a poor welcome for anyone who cannot read it.
  It now opens on a bilingual chooser — the one screen that cannot assume a language,
  so it says each line twice. `1` picks Chinese, `2` picks English, the arrow keys and
  `Enter` do the same, and `l` still switches at any time afterwards. Naming the
  language up front skips the chooser: `run.bat --lang zh`, `--lang en`, `--lang=zh`,
  `--zh`, `--en`. An unrecognised value falls back to the chooser rather than
  guessing, and the plain menu (`--simple`) keeps its own default.
- **`tools/Test-TuiScroll.ps1`** — the check the gates cannot make. It paints a
  frame in a real console window, repaints it, then reads the whole console buffer
  back and compares it against the frame it meant to draw. It also paints with the
  old code as a control and fails the run if that control does not reproduce the
  scroll, so a clean result cannot come from a test that detects nothing.
- **A full-screen TUI.** The interactive interface is now a keyboard-driven,
  panel-based application instead of a numbered menu: a header showing the armed
  plan and its size, a category pane with per-category selected counts, an
  action pane with checkboxes, a detail pane that states what the focused action
  touches, and a key/status footer.
  - Arrow keys move, `Tab` switches panes, `space` toggles, `Enter` opens a
    category and steps down, `a`/`n`/`A`/`N` select by
    category or wholesale, `l` switches language, `p` previews, `x` applies,
    `?` shows in-app help.
  - It draws into the alternate screen buffer, so the terminal scrollback survives
    the session, and the terminal is restored from a `finally` block.
  - Legacy consoles get VT processing enabled through the Windows API; if that
    fails, or output is redirected, the TUI declines and the plain path is used.
- **`--simple`** (and `-Tui:$false`) keeps the previous numbered menu, for
  automation, screen readers, and terminals without ANSI support.
- **Two new test gates.** `tests/Test-Tui.ps1` (57 checks) covers the navigation,
  selection and scroll-window logic; `tests/Test-TuiRender.ps1`
  (54 checks) covers the frame geometry, pane borders, checkbox rendering, the help
  screen, and that rendering never mutates state.
- `src/lib/Tui.Logic.ps1`, `src/lib/Tui.Render.ps1`, `src/lib/Tui.Input.ps1`.
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
- **`tests/Test-Parse.ps1`** — the syntax gate. Parses every PowerShell file and
  verifies the file-encoding rules (BOM for `.ps1`/`.psd1`, no BOM and CRLF for `.bat`).
- **`tests/Test-Analyzer.ps1`** — the lint gate, runnable locally and in CI.
- **`docs/LINTING.md`** — why syntax and lint are separate gates, the current finding
  counts, and the reasoning behind each excluded rule.

### Changed
- **Presets are gone.** There were three tiers to choose between before you could do
  anything, and a tier is a decision made on your behalf: picking `balanced` silently
  opted you into 15 actions you never looked at. The catalog now marks one starting set
  instead — the 45 low-trade-off actions that used to be `conservative` — and the tool
  opens with exactly those checked. Everything else is a single `space` away, nothing
  re-adds an action you turned off, and the `1` / `2` / `3` keys, the header label, the
  per-action preset line and the `-Preset` switch are all gone rather than hidden.
  `-Only` still replaces the starting set outright, so per-item deselection keeps
  working.
- **The action column is now only the action list, and the detail text moved to a
  panel under the categories.** The list runs the full height of the body — 21 rows
  at 100x30, where the old 55% split gave it 15 — and nothing about it changes shape
  when the cursor moves. The detail panel answers "what does this actually do?" for
  the focused action, with the rationale and the target wrapped across the rows it
  has instead of being cut. Its height is a function of the terminal size alone, so
  neither the cursor nor a change of category can move it, and its label rides on
  the divider row so it costs no extra line. The category column is a little wider
  (42%) because it now carries the wrapping text, and the panel gives the title only
  the rows it needs, so a one-line title no longer leaves a gap while the target is
  truncated at the bottom.
- `WinCleanKit.bat` is now purely an elevation launcher: cmd cannot read arrow
  keys, so a full-screen interface is impossible there. It hands the session to the
  engine's TUI and keeps the numbered menu behind `--simple`.
- Category display names shortened so they fit the TUI's list pane without
  truncation ("Ads & suggestions" rather than "Windows ads & suggestions").
- `docs/CATALOG.md` regenerated for the new names.
- The front-end no longer calls `CLS` on every screen. It repositions the cursor
  and redraws over the previous frame, which removes the flash and keeps the last
  25 lines available as scrollback.
- The front-end header uses the engine's divider style, so the two surfaces match.
- The READMEs lead with what the tool actually looks like — real menu, plan and
  apply output — plus build badges whose numbers are verified against the catalog
  and the gate results.
- The `origin` remote points at the public GitHub URL. The internal Gitea mirror is
  a separate remote named `gitea`, so a clone never reveals an internal address
  through `git remote -v`.

### Removed
- **The risk level, everywhere.** Every action used to carry a `低` / `中` / `高`
  label, the catalog stored it in a `risk` field, the TUI printed it beside each
  action and named the highest one in the header, the generated catalog had a risk
  table, and the docs asked you to read it before choosing. It was noise. The
  levels restated the same three tiers the presets imposed, and they were not a
  measurement — a label that says "medium" without saying medium *of what* is a
  number dressed up as a judgement, and it pushed people to defer to it instead of
  reading the sentence next to it. The `risk` field, the `低`/`中`/`高` rendering,
  the highest-risk header line and the per-action tag are all gone rather than
  merely unrendered; what each action does to your machine is stated in its
  description and its `touches` target, which is the part that was always doing the
  work. Removing the field from the catalog is checked by
  `tests/Test-Catalog.ps1` ("the risk field is gone from every action") so it
  cannot creep back in through a catalog edit.

### Fixed
- **The language toggle redrew nothing.** On a real console, `l` switched the
  language in the state and left the previous frame on screen, so the key read as
  dead: pressing it twice produced a byte-identical screen. The key loop repainted
  only when a hand-written list of state fields differed from the state it captured
  before the keypress, and the language was not on that list, so the loop concluded
  nothing had moved and skipped the frame even though every visible row was now
  wrong. Found by driving the deployed build — sending keys to the live window from
  a scheduled task in the interactive session and reading the console buffer back —
  where `?`, `Esc`, `Tab`, the arrow keys and `space` all repainted (the action
  count visibly went 45 → 46 → 45) while `l` did not. The field list is now
  `Get-TuiRenderStamp` in `Tui.Logic.ps1`, one function that names everything a
  frame is drawn from, and `tests/Test-Tui.ps1` holds it to the renderer's own
  source: every `$State.<field>` the renderer reads must change the stamp, so a new
  field cannot be drawn without also being repainted.
- **The whole interface sat one row too high and jumped on every keypress.**
  `Format-TuiFrame` wrote a carriage return and line feed after every row, the last
  one included, and every row is exactly as wide as the terminal. On a window of N
  rows that advances the cursor past the bottom line, so the console scrolls: the
  frame was already one row off the moment it was painted, and the same thing
  happened again on each repaint. This is the failure the gates could not see — the
  frames were correct, only the painting was wrong, and no automated run had ever
  looked at what the terminal did with them. Painting now follows Terminal.Gui's
  NetDriver, the driver behind Microsoft's Out-ConsoleGridView: each row is
  positioned absolutely and no line feed is written at all, the console's
  `DISABLE_NEWLINE_AUTO_RETURN` output mode is set and `ENABLE_WRAP_AT_EOL_OUTPUT`
  cleared, and the screen buffer is pinned to the window size so no scrollback
  exists for a stray line feed to scroll. `ESC[K` is gone too: erasing to end of
  line from the last column rubs out that row's final character.
- **`run.bat` / `WinCleanKit.bat` could not start at all when launched the way a
  user launches them.** cmd re-resolves a parameter that carries a script path
  against the *current* directory on every expansion, not the directory the file
  was called from. Because `run.bat` called the relative `src\WinCleanKit.bat`, the
  callee's `cd` into `src\` made the next expansion of its own folder yield
  `src\src\`, so every path it built pointed one level too deep and PowerShell
  failed with "The argument ... does not exist". The folder and the script path are
  now read once into `WCK_SRC` / `WCK_BATSELF` before anything changes directory,
  and `run.bat` calls the launcher through its own absolute path. Elevation used
  `%~f0` and was broken the same way; it now uses `WCK_BATSELF`.
- **A commented-out `%~fI` made the whole file a parse error.** cmd expands
  parameter-substitution syntax *even inside `rem`*, so the file failed with "the
  following usage of the path operator in batch-parameter substitution is invalid"
  and printed nothing useful. No comment carries that syntax any more, and
  `tests/Test-Parse.ps1` fails if one comes back.
- **`chcp` silently discarded the caller's standard input.** Driving the numbered
  menu from a file or a pipe lost its first lines at the `chcp 65001` line, so the
  menu saw end-of-input before the first answer. `chcp` is now handed `<nul`; the
  interactive reads downstream keep the real stream.
- **The numbered menu could not be scripted or piped at all.** `set /p` leaves its
  target variable unchanged at end of input, so the menu reprinted itself as fast
  as cmd could loop. Every prompt now goes through one `:ask` helper that seeds a
  sentinel value, distinguishes "the user pressed Enter" from "there is no more
  input", and unwinds cleanly through the menu labels when the stream ends.
- **Both panes drew the focus arrow at the same time.** The action pane marked its
  cursor row with `>` even while the keyboard was in the category pane, so the
  frame showed two focus markers and no way to tell where input would land. Only
  the focused pane draws `>`, as it always did on the left; the other pane marks
  its cursor row with `-`.
- **The detail block moved around and left the pane half empty.** It sat directly
  under the action list, so a category with one action pushed it near the top and a
  long one put it in the middle, and because the list was pinned to 55% of the
  height, five rows sat blank underneath a rationale that had already been cut off
  with an ellipsis. The pane is now one stable shape: the action list fills every
  row except the detail block, which is pinned to the bottom and sized from the
  terminal height, so it cannot move. The rationale and the "touches" line wrap
  across the rows they are given instead of being cut, and carry an ellipsis only
  when the text genuinely does not fit.
- **The menu-data reads failed inside `for /f`.** A command containing double
  quotes is torn apart unless the loop is declared `usebackq`, so invoking the
  helper by full path reported "cannot find the file"; and calling a batch label
  inside the backticks spawned a child process that lost batch-label context,
  printing "Invalid attempt to call batch label outside of batch script" on every
  screen. All twelve call sites are now direct `usebackq` invocations.
- `WinCleanKit.bat` also gained a preflight check: if the expected files are
  missing it now names the exact missing path and prints the expected layout,
  instead of letting PowerShell report a confusing path error several steps on.
- **The `--simple` switch was lost on elevation.** The elevated instance is a fresh
  process, so a user who asked for the accessible menu was dropped into the
  full-screen one. The switch is now resolved before elevation and forwarded.
- **The plain menu was unreachable when the TUI could not start.** The TUI
  reported the fallback and then exited 0, so the front-end treated that as
  success and terminated silently. The TUI now distinguishes "this console cannot
  draw" (exit 3) from "the user quit" (exit 0), and the front-end falls through to
  the numbered menu on 3.
- A duplicated block-comment terminator and a stale function name in
  `Tui.Input.ps1`, and a name that a bulk rename had doubled into
  `Show-TuiSessionSession`. Three functions now have distinct names:
  `Open-InteractiveSession` (engine wrapper), `Show-TuiSession` (entry point),
  `Show-TuiInteraction` (the key loop).
- PSScriptAnalyzer caught two problems introduced by the refactor: an empty
  `catch` block (now documents why swallowing is correct there) and a
  state-changing verb on a progress helper (`Start-Progress` renamed to
  `Initialize-Progress`).
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
- The batch fixes above were verified on Windows PowerShell 5.1 / Windows 11 by
  driving the numbered menu from a scripted input file: quit, about, the language
  toggle, category selection, per-item selection, preview, apply-cancel,
  apply-confirm and restore all exit 0 with no cmd error text, in
  both call styles (`run.bat` and the inner `WinCleanKit.bat`, relative and
  absolute). All eight gates pass.
- `tests/Test-Parse.ps1` gained five checks that pin the batch launcher rules:
  `chcp` must keep stdin, no script path may be expanded after the working
  directory moves, every prompt must go through `:ask`, and `run.bat` must capture
  its folder before `cd` and call the launcher absolutely.
- **What is still verified by hand, stated plainly:** the key loop itself. Reading
  keys and repainting needs a real interactive console, which no automated run has.
  It is kept deliberately thin, guarded statically by the parse and lint gates, and
  every function it dispatches to is covered by tests/Test-Tui.ps1. What the
  terminal does with the frame is now covered by `tools/Test-TuiScroll.ps1`, which
  must be run by hand in a real console window but reads the buffer back and judges
  the result objectively instead of by eye.
- The TUI reuses the engine's own preview and execution paths rather than
  duplicating them, so a change to how a plan is applied cannot drift between the
  two interfaces.
- `CONTRIBUTING.md` now documents the bilingual contract, the English-only exceptions
  (with reasons), and the rule against committing internal addresses.
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
