[English](SECURITY.md) · [中文](SECURITY.zh-CN.md) · **Docs:** [README](README.md) · [Usage](docs/USAGE.md) · [Safety](docs/SAFETY.md) · [Limitations](docs/LIMITATIONS.md) · [Catalog](docs/CATALOG.md) · [Linting](docs/LINTING.md)

# Security Policy

## Scope

WinCleanKit modifies operating-system settings with administrator privileges. The
security-relevant properties of this project are therefore:

1. **It must not do anything the user did not select.** The catalog is the complete
   description of what can change. If a code path can modify the system outside the
   catalog, that is a vulnerability.
2. **It must be honest about failure.** A silently-dropped write or a skipped action
   must never be reported as success.
3. **It must not weaken the machine's security posture.** No action may disable Defender,
   the firewall, BitLocker, SmartScreen, or Windows Update.
4. **Privilege handling must be minimal.** The front-end elevates in order to write to
   `HKLM`, and nothing more.

## Supported versions

| Version | Supported |
|---|---|
| `0.1.x` | ✅ |

## Reporting a vulnerability

Please **do not** open a public issue for a security problem. Report it privately by
opening a confidential security advisory in the repository, or contact a maintainer
directly. Include:

- the affected version (or commit)
- the exact command or menu path
- what you expected to happen and what happened
- the relevant part of `run.log`, if a run occurred
- whether the issue requires an already-compromised machine

You will get an acknowledgement as soon as a maintainer sees it. Please allow a
reasonable window for a fix and a release before public disclosure.

## Known and accepted limitations

These are documented behaviour, not vulnerabilities:

- **The tool makes system-wide changes by design.** Running it on a machine you do not
  administer, or without reading the preview, is a usage problem rather than a defect.
- **Protected registry keys may refuse a write.** The engine reports this. It does not
  take ownership of keys to force the change — forcing ownership of system keys would be
  a worse security outcome than the setting it is trying to apply.
- **Uninstalled Store apps are not restored automatically.** The restore script lists
  what to reinstall.
- **`AllowTelemetry = 0` is capped to *Required* on Pro/Home editions.** A platform limit;
  see [LIMITATIONS.md](docs/LIMITATIONS.md).

## What we will not do

To be explicit about requests we decline, because they come up:

- Force ownership or rewrite ACLs on protected system keys, services or tasks.
- Modify the `hosts` file to block Microsoft domains.
- Disable Windows Defender, the firewall, BitLocker, or Windows Update.
- Ship a bundled binary, installer, or downloader. This project is scripts and data.
