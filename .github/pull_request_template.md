<!--
  Thanks for contributing. Please keep this short — the diff and the run log tell
  most of the story.
-->

## What this changes

<!-- One or two sentences. If it adds or changes catalog actions, name the ids. -->

## Type

- [ ] New action(s) in `catalog/catalog.json`
- [ ] Change to an existing action
- [ ] Engine / front-end code
- [ ] Documentation
- [ ] CI / tooling

## Affected actions

<!-- Action ids, e.g. `ads.cdm.silent-install`. Use "n/a" for code-only changes. -->

## Does this change what a preset does?

<!-- If yes, say which preset and what users will now get or lose. This matters
     to people who never read the changelog. -->

- [ ] No
- [ ] Yes — described above

## How it was verified

- [ ] `.\tests\Test-Catalog.ps1` passes
- [ ] `.\tests\Test-Engine.ps1` passes (Windows)
- [ ] Manually tested on Windows build: <!-- e.g. 26200 -->

<!-- If the change touches the .bat or a .ps1 encoding, confirm:
     - .bat is UTF-8 WITHOUT BOM and CRLF
     - .ps1 is UTF-8 WITH BOM and CRLF
     The test suite checks both, but a note here saves a round trip. -->

## Checklist

- [ ] Every new action documents what it does **and what it costs**, in both languages
- [ ] New ids follow `category.specific-name` and do not rename an existing id
- [ ] The preset containment chain still holds (`conservative ⊆ balanced ⊆ aggressive`)
- [ ] No action touches the `hosts` file, Windows Update, the wallpaper, or user data
- [ ] `docs/CATALOG.md` regenerated if actions changed
