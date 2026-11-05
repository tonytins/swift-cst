# Change Log

## 0.3.0

Added:

- `UIText.textIfPresent(for:key:variables:)`, which finds the same text as
  `text(for:key:variables:)` but returns `nil` rather than `*** MISSING ***` when the
  table or key is missing, the value was never closed, or a reference can't be followed
- `UIText(gameData:language:)`, which reads an install's `gamedata` directory in either
  layout: New & Improved's `uitext/<language>.dir`, or the earlier `uitext.dir`

Nothing existing changes. Across the beta, base game, and New & Improved, `textIfPresent`
returns the same text as Hudini's `CSTCatalog` for every key, every miss probed, and every
string the game's `.uis` files use.

## 0.2.0

SwiftCST can now read real The Sims Online tables. The reader was rewritten against the
files from three versions of the game, and [the CST specification](CST.md) is now part of
this project.

Changes that can affect existing code:

- Keys must match whole, so `ok` no longer finds `ok button`. These lookups now return
  `*** MISSING ***`.
- `%%` becomes one `%`, even with no variables.
- `%3d` pads with spaces rather than zeros, as C's `printf` does. `%03d` and `%.3d` still
  pad with zeros.
- A negative number keeps its sign in front when padded, so `%03d` gives `-05` rather than
  `0-5`.
- `UIText` reads each table once, so changes to a file after its first lookup aren't seen.
- `UIText` no longer throws on non-UTF-8 files.

Added:

- `CSTTable`, which reads a document once and gives its values in file order, lookups that
  return `nil` when a key is missing, and a list of problems found
- `CST.format(_:with:)`, which fills a value's placeholders
- `UIText.table(for:)`, which returns a whole table

Parsing:

- Indented keys and keys with spaces
- Names above values, with blank lines or comments between them
- Byte order marks
- A value that's never closed no longer swallows a following key with spaces
- A line that merely ends in `*/` is no longer dropped

`UIText`:

- Windows-1252 files
- Values with no key, found by position from 0
- References between tables
- Faster lookups, because each table is parsed once

Placeholders:

- `%i`, `%u`, `%ld`, and `%.2d`
- `%%d` no longer uses up a variable

## 0.1.2

- `UIText` lookups from language catalog directories, searching beside the executable first
- Comments and unclosed values no longer run into later entries
- Parsing and file lookups are synchronous, and the async overloads are deprecated
- VS Code syntax highlighting

## 0.1.1

- Backwards compatibility with macOS 12 and older
- Asynchronous support

## 0.1.0

- Initial release
