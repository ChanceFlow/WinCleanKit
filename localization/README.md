# Localization

## Where the strings actually live

The interactive front-end is a `.bat` file, and batch has no practical mechanism for
loading keyed strings at runtime. Rather than pretend otherwise, WinCleanKit keeps its
text where it is used, and the test suite enforces that both languages are present:

| Surface | Location | Languages |
|---|---|---|
| Action titles and reasons | `catalog/catalog.json` — `title` / `title_zh` and `why` / `why_zh` | English, Chinese |
| Front-end menu text | `src/WinCleanKit.bat` (bilingual literals) | English, Chinese |
| Engine console output | `src/WinCleanKit.ps1` — selected by `-Language en\|zh` | English, Chinese |

The catalog is the important one: **an action without both languages fails validation.**
A user should never have to decide about a change they cannot read.

## Adding a language

1. Add `<field>_xx` variants to every action in `catalog/catalog.json`.
2. Extend the `L` helper in `src/WinCleanKit.ps1` and `src/menu/menu.ps1` to fall back
   through your new language.
3. Add the code to the `-Language` `ValidateSet` in both scripts.
4. Add the literals to `src/WinCleanKit.bat` and extend its language toggle.
5. Add the language to the tests in `tests/Test-Catalog.ps1` (required fields) and
   `tests/Test-Engine.ps1` (output checks).

## Encoding rules

Non-ASCII text depends on these, and CI enforces both:

- **`.bat` — UTF-8 *without* BOM, CRLF line endings.** A BOM prints as garbage before
  `@echo off`; LF-only line endings confuse `cmd`. The file sets `chcp 65001` itself.
- **`.ps1` — UTF-8 *with* BOM.** Windows PowerShell 5.1 decodes a BOM-less script using
  the machine's ANSI codepage, which turns Chinese strings into mojibake. This is the
  single most common way to break this project. Line endings are not enforced for
  PowerShell files, because the interpreter accepts either; `Test-Parse.ps1` checks the
  BOM (exactly one of them) and the `.bat` rules.
