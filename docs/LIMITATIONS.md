[English](LIMITATIONS.md) · [中文](LIMITATIONS.zh-CN.md) · **Docs:** [README](../README.md) · [Usage](USAGE.md) · [Safety](SAFETY.md) · [Limitations](LIMITATIONS.md) · [Catalog](CATALOG.md) · [Linting](LINTING.md)

# Known limitations

Honest boundaries. Some are platform limits no tool can cross, some are deliberate choices.

## Windows edition limits diagnostic data

Setting `AllowTelemetry = 0` is honoured fully only on **Enterprise** and **Education** editions. On **Pro** and **Home**, Windows treats it as *Required*: a reduced set of security- and quality-related diagnostic data is still sent, and this cannot be changed by any setting, policy, or third-party tool.

What WinCleanKit *can* do on Pro/Home, and does:

- stop the collection and upload services (`DiagTrack`, compatibility appraiser, CEIP, USB CEIP, feedback upload)
- stop error reporting and the compatibility assistant
- disable OneSettings configuration downloads
- set the policy to its lowest permitted value

This reduces the practical volume to near the platform minimum. It does not reach zero. If you need zero, you need Enterprise/Education or Windows LTSC.

Verify what your build actually reports with:

```powershell
Get-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' -Name AllowTelemetry
dsregcmd /status   # shows the effective diagnostics state under "DiagnosticData"
```

## Some keys and tasks are protected by Windows

Windows protects a small number of registry keys and scheduled tasks against modification, even for administrators. Examples observed in testing on Windows 11 build 26200:

- `HKCU\...\CurrentVersion\Search\BingSearchEnabled` — writes fail with *Access is denied* even though the owner is your own account and the ACL grants `FullControl`
- `HKLM\SOFTWARE\Policies\Microsoft\Dsh` on some builds

The engine reports these as `[WARN]`/`[FAIL]` in the run log rather than pretending they worked, and does **not** take ownership of keys to force the write. Forcing ownership of system keys is exactly the kind of change that causes hard-to-diagnose problems later. When a write is refused, use the documented UI equivalent instead (for example, Settings → Privacy & security → Search permissions).

## Scheduled tasks may be re-created by Windows feature updates

Major Windows updates can re-enable telemetry tasks or restore promoted-content defaults. Re-running WinCleanKit is safe and idempotent — it re-applies only what you select. A dry run is a quick way to see what drifted.

## OneDrive uninstall depends on the environment

`OneDriveSetup.exe /uninstall` returns `0x800704C7` (user cancelled) when run in a non-interactive session such as over SSH, because it expects a desktop session. The engine therefore removes the client binaries directly as a fallback and blocks reinstall by policy. The **data folder is never touched**, so the disk space it occupies is only reclaimed if you delete it yourself after confirming it holds nothing you need.

## Wallpaper is not a setting, so it is not "debloated"

If Windows is currently showing a Spotlight promotional image as your desktop wallpaper, WinCleanKit stops *future* delivery and hides the promotional overlay, but it does not repaint your desktop. Delete or change the current image through Settings → Personalisation → Background. This is deliberate: a tool that silently changes your wallpaper is doing the exact thing this project exists to avoid.

## The catalog is Windows 11 first

Actions are written and tested against Windows 11 (build 26200). Most registry policy paths also work on Windows 10, and actions whose services or tasks are absent are reported as *not installed* rather than failing. Windows 10-only surfaces (News and interests, for example) are not covered yet.

## No undo for content that was deleted

The restore journal covers settings, services and tasks. Deleted ad images stay deleted, and uninstalled Store apps must be reinstalled from the Store. The restore script tells you which ones.

## Not a hardening tool

WinCleanKit reduces advertising and telemetry. It is not a security-hardening baseline, it does not configure Defender, firewall rules, BitLocker, or an application allowlist, and it should not be treated as one.
