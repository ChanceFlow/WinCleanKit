<!--
  The front page of the downloadable package, written as if it sat at the
  repository root: the packager copies it to README.md in the package and strips
  the leading "../" from its links, so the same text works in both trees. It is
  deliberately not the project page -- no badges, no CI status, no contributing
  section, and no link to a file the download does not contain.
-->

# WinCleanKit

A user-first Windows 11 de-bloater. It closes Microsoft's ads and telemetry and
removes the bundled apps you never asked for -- and it changes nothing you did not
tick yourself.

**English** · [中文说明](README.zh-CN.md)

## Run it

1. Put this folder anywhere. Your Desktop is fine.
2. Double-click **`run.bat`**. A window opens.
3. Accept the elevation prompt -- machine-level settings need administrator rights.
4. Pick your language, read the list, tick what you want, and press **Apply**.

Windows 10 1809+ or Windows 11, with Windows PowerShell 5.1 or PowerShell 7+.

Nothing is written until you confirm the plan, and the first thing a run does is
write a restore point to your Desktop. If you want the settings back, run
`Restore-WinCleanKit.ps1` from that folder.

## If the window does not appear

| Situation | What to run |
|---|---|
| No desktop here (a remote session, a scheduled task) | `run.bat --tui` -- the full-screen console interface |
| Old terminal, screen reader, or you just prefer plain text | `run.bat --simple` |
| You want to skip the language chooser | `run.bat --zh` or `run.bat --en` |
| Try the whole plan without changing anything | `run.bat --gui --dry-run` |
| Automating it | `src\WinCleanKit.ps1 -Apply -NoPrompt -Only telemetry` |

## What is in this folder

| Path | What it is |
|---|---|
| `run.bat` | The launcher. Double-click this one. |
| `src/` | The tool: a batch front-end and a PowerShell engine. |
| `catalog/catalog.json` | All 74 actions as data. Re-word one and the interface follows. |
| `docs/` | Usage, safety, known limits, and the full action catalog. |
| `LICENSE` | MIT. |

This is the download, not the repository. The test suites, the documentation
generators and the CI definitions are not in here -- they exist for people changing
the tool, not for people running it.

## Before you run it

| Read | Why |
|---|---|
| [docs/USAGE.md](../docs/USAGE.md) | Every switch, and what the two interfaces do. |
| [docs/SAFETY.md](../docs/SAFETY.md) | What is backed up, what is not, and running it on a work machine. |
| [docs/LIMITATIONS.md](../docs/LIMITATIONS.md) | Where Windows overrides the tool, and what it refuses to touch. |
| [docs/CATALOG.md](../docs/CATALOG.md) | All 74 actions, each with its reason and what it touches. |

The full project -- source, tests, issue tracker -- is at
<https://github.com/ChanceFlow/WinCleanKit>.
