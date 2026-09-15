[English](SAFETY.md) · [中文](SAFETY.zh-CN.md) · **Docs:** [README](../README.md) · [Usage](USAGE.md) · [Safety](SAFETY.md) · [Limitations](LIMITATIONS.md) · [Catalog](CATALOG.md) · [Linting](LINTING.md)

# Safety

WinCleanKit changes operating-system settings. That deserves plain talk about what it does, what it refuses to do, and how to get back.

## What it refuses to touch

These are enforced in code and tested by the suite, not just promised in a README:

| Never touched | Why |
|---|---|
| **The `hosts` file** | Blocking telemetry by DNS is the most common advice on the internet and the most likely to break things. It can take down Windows Update, the Microsoft Store, and — on corporate machines — VPN and SSO logins. WinCleanKit does not go near it. |
| **Your personal files** | No action reads or deletes anything under your user profile except the explicit cache paths listed in the catalog. |
| **Your wallpaper** | The desktop wallpaper and its transcoded copy (`TranscodedWallpaper`) are left alone. The cache action deletes downloaded *Spotlight ad images*, which are a different thing. |
| **Your OneDrive data folder** | The OneDrive action uninstalls the client and blocks reinstall. It refuses to run at all if your Desktop or Documents are redirected into OneDrive, because that would leave you without those folders. |
| **Windows Update** | `wuauserv`, `UsoSvc` and `BITS` are never disabled. Security patches are not bloat. |
| **Delivery Optimization (`DoSvc`)** | It is an update accelerator, not telemetry. You can opt out of its peer-to-peer sharing as a separate action. |
| **Edge as a browser** | Only its promotional tabs and the "set me as default" popup are turned off. |
| **Your diagnostics service (`DPS`)** | Kept enabled — network troubleshooting depends on it. |

## How changes are made reversible

Before the first change of a run, the engine prepares a journal. It records, for every action:

- the **registry** path, value name, whether it existed, its **exact previous value** and its type
- the **service** name, previous start type and previous running state
- the **scheduled task** path, name and previous state
- the **appx** packages that were removed (so you know what to reinstall)
- the **cache paths** that were emptied

At the end of the run this becomes:

```
Desktop\WinCleanKit-<timestamp>\
├── backup.json                 machine-readable original state
├── Restore-WinCleanKit.ps1     one-click undo
└── run.log                     one line per action
```

The restore script reverses registry values exactly, restores service start types and their running state, and re-enables scheduled tasks. It is idempotent — running it twice is harmless.

**What restore does not do:** it cannot undelete cached ad images, and it does not re-download uninstalled Store apps. It tells you which packages to reinstall.

## Before you run it on a work machine

1. **Check your organisation's policy.** On a managed or domain-joined PC, some settings may be enforced by Group Policy; your changes may be reverted at the next policy refresh, or may conflict with your IT department's management. WinCleanKit does not detect this.
2. **Know what you use.** If you rely on Game Bar recording, Phone Link, the new Outlook, Sticky Notes, Microsoft To Do, or OneDrive, leave those actions off. None of them is in the default selection, and each is individually skippable.
3. **Take your own backup first** if the machine matters. A system image or restore point is a stronger guarantee than a settings journal.
4. **Read the plan.** The preview shows every action and its reason. It takes thirty seconds.

## Verify before you trust

```powershell
# Static validation: catalog integrity, safety invariants, encoding. Changes nothing.
.\tests\Test-Catalog.ps1

# Behavioural validation: preview never writes, -Only is authoritative, dry run is clean.
.\tests\Test-Engine.ps1
```

Both suites are read-only. `Test-Engine.ps1` uses only `-Plan` and `-DryRun`, and asserts that a dry run creates no restore point.

## Reporting a safety problem

If you find a path where the tool changes something it should not, or fails to restore something it recorded, please open an issue with the affected action id and the relevant part of `run.log`. For anything that looks exploitable, use the security policy in the project repository (`SECURITY.md`).
