# Linting and syntax gates

Three gates run in CI and can all be run locally. None of them change anything.

```powershell
.\tests\Test-Parse.ps1      # syntax: the PowerShell parser, plus file-encoding rules
.\tests\Test-Analyzer.ps1   # style and correctness: PSScriptAnalyzer
.\tests\Test-Catalog.ps1    # data integrity and safety invariants
.\tests\Test-Engine.ps1     # behaviour: selection semantics, dry-run purity
```

`Test-Parse.ps1` needs nothing installed. `Test-Analyzer.ps1` needs PSScriptAnalyzer:

```powershell
Install-Module PSScriptAnalyzer -Scope CurrentUser -Force
```

---

## Why syntax and lint are separate gates

They answer different questions and fail for different reasons.

| Gate | Question | Tool |
|---|---|---|
| **Syntax** | Is this valid PowerShell that will load and run? | `[System.Management.Automation.Language.Parser]` |
| **Lint** | Is it correct and consistent, and does it avoid known footguns? | PSScriptAnalyzer |

A file can be perfectly valid syntax and still be wrong (an unused parameter, a
state-changing function without its guard). It can also be valid style and fail to
parse. Both gates are therefore mandatory.

`Test-Parse.ps1` also verifies the encoding rules, because in this project encoding *is*
a correctness property:

| File type | Required encoding | Why |
|---|---|---|
| `*.ps1`, `*.psm1`, `*.psd1` | UTF-8 **with BOM**, CRLF | Windows PowerShell 5.1 decodes a BOM-less script using the machine's ANSI codepage. Without the BOM every Chinese string becomes mojibake. |
| `*.bat` | UTF-8 **without BOM**, CRLF | A BOM would be printed as garbage before `@echo off` runs, and `cmd` requires CRLF. |

---

## PSScriptAnalyzer result

Current state with the repository ruleset, on PowerShell 5.1.26100 and PSScriptAnalyzer 1.25.0:

```
Error       : 0
Warning     : 0
Information : 0
```

With the **full default** ruleset (no repository settings), the same code reports 143
findings and **0 errors**. Two rules account for nearly all of them, and both are
deliberate:

| Rule | Count | Why it is excluded |
|---|---|---|
| `PSAvoidUsingWriteHost` | 94 | This is an interactive console application. Coloured terminal output *is* the interface, and the engine is invoked as a script, not as a pipeline cmdlet. `Write-Host` is the right tool; switching to `Write-Output` would corrupt the machine-readable output modes. Each console helper also carries an inline suppression naming this reason. |
| `PSAvoidUsingPositionalParameters` | 40 | Every instance is a call to one of the `Write-*` console helpers or to `Get-OptProp`, all of which take a single mandatory string. `Write-Info "text"` is unambiguous and reads far better than `-Text` repeated at ~90 call sites. |

Everything else was fixed in the code rather than excluded. The rules that point at real
defects are deliberately left enabled:

| Rule | Status |
|---|---|
| `PSReviewUnusedParameter` | enabled — found a genuinely unused parameter, which was removed |
| `PSUseApprovedVerbs` | enabled — three helper names were renamed to approved verbs |
| `PSUseSingularNouns` | enabled — two functions suppress it inline with a justification |
| `PSUseShouldProcessForStateChangingFunctions` | enabled — one function suppresses it inline with a justification |
| `PSUseBOMForUnicodeEncodedFile` | enabled — caught a missing BOM in the settings file itself |
| `PSUseCompatibleSyntax` | enabled, targeting 5.1 and 7.0 |

### Fixes the analyzer prompted

These were real problems, not style preferences:

1. **`Invoke-OneDriveAction` declared an `$Action` parameter it never used.** The
   OneDrive action needs no per-action metadata. Parameter and call site removed.
2. **The name `New-Journal` asserted a state change it does not make.** The function
   deliberately creates nothing — the run directory is created lazily so a dry run
   leaves no trace. Renamed `Initialize-Journal`.
3. **`Emit-Plan` was dead code**, left over from an earlier handoff design. Deleted.
4. **`Write-Journal` was being called positionally.** Now always `-Message`.
5. **The `.psd1` had non-ASCII comments without a BOM**, which the analyzer's own
   encoding rule caught.

### A note on `SuppressMessageAttribute`

The attribute is only valid **inside a function body, immediately before `param()`**.
Placing it above a `function` keyword is a parse error, and in Windows PowerShell 5.1
`[CmdletBinding(SupportsShouldProcess)]` is not valid on a function at all — it requires
a `param()` block. Getting this wrong is easy, which is why `Test-Parse.ps1` exists and
runs before the lint gate.

Suppressions in this codebase always carry a `Justification`, so the reason is readable
where the code is, rather than hidden in a config file.
