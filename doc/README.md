# SwiftCST

SwiftCST is a library for parsing Maxis' key-value pair format.

## What is CST?

Caret-Separated Text (or CST) is a string-text format: a plain-text resource format with digits or words as keys and each value enclosed between carets. (e.g. `<key> ^<value>^`) Maxis used it as early as Sims Steering Committee, a prototype of The Sims, and later in The Sims Online for its interface text.

## Usage

### Basics

If you want to create your own framework based on SwiftCST, you can use the `CST` struct directly.

```swift
let quickFox = "1 ^The quick brown fox jumps over the lazy dog.^"
let cst = CST.parse(content, key: 1)

print(cst)
```

### Variables

You may need to parse one or more variables.

```swift
let quickFox = "1 ^The quick brown fox %s over the lazy dog.^" // %s represents a string variable
let cst = CST.parse(quickFox, key: 1, variables: "leaps")


print(cst)
```

### Keys

You are not limited to numbers as keys. In fact, both text and event emojis are valid.

```swift
// %d represents digits.
let input = """
🦊 ^The quick brown fox %s over the lazy dog.^
mail ^You have %d new messages^
"""

let quickFox = CST.parse(input, key: "🦊", variables: "leaps")
let mail = CST.parse(input, key: "mail", variables: 5)

let output = """
\(quickFox)
\(mail)
"""

print(output)
```

Keys must match whole, so `ok` doesn't find `ok button`. Keys can contain spaces
and can be indented.

A number followed by a period or colon is a numbered key, as Sims Steering Committee
writes them. `1.window name` on the line above a value, or `1:` before it, gives the key
`1`, and any text after the separator becomes the value's name, so either finds it.

Whole-line `//` and `#` comments are ignored. Block comments beginning with
`/*` are ignored through the line containing `*/`. These comment lines are also
ignored inside multiline values. An unterminated value does not consume later
entries.

See [the CST specification](CST.md) for the full format.

### Placeholders

Variables fill placeholders in order. Padding follows C's `printf`.

| Placeholder | Fills in | 7 becomes |
| --- | --- | --- |
| `%s` | Text | `7` |
| `%d`, `%i`, `%u`, `%ld` | A number | `7` |
| `%3d` | A number, at least 3 characters, filled with spaces | `  7` |
| `%03d` | A number, at least 3 characters, filled with zeros | `007` |
| `%.3d` | A number, at least 3 digits | `007` |
| `%%` | One percent sign, using no variable | |

A placeholder with no variable left stays as written, so a mistake is visible, and
any other use of `%` is left alone.

### CSTTable

`CST.parse` reads the whole document on every call, and returns `*** MISSING ***`
for a missing key. `CSTTable` reads it once, and its lookups return `nil` instead:

```swift
let table = CSTTable(input)

if let mail = table.value(forKey: "mail") {
  print(CST.format(mail, with: [5]))
}
```

This is the layer to build on if you're writing your own wrapper. `entries` lists every
value in file order with its `key`, `name`, and `value`. A value that was never closed
stays in the list with a `nil` value, so its offset in the list is still its position.
`problems` lists unclosed values and repeated keys with their line numbers. Values are
returned untouched, so use `CST.format(_:with:)` to fill their placeholders.

Reading a table never fails. A malformed entry is reported, and the rest of the table
stays usable.

### UIText

`UIText` reads a key from a language catalog file named
`_<id>_<name>.cst`. By default it searches for `uitext` beside the running
executable first, then falls back to the app bundle's `uitext` resources:

```swift
let english = UIText(language: "english")
let newMail = try english.text(for: 101, key: "newMail", variables: 5)

print(newMail)
```

For another language, pass its directory name and the directory containing
language catalogs:

```swift
import Foundation

let swedish = UIText(
  language: "swedish",
  basePath: URL(fileURLWithPath: "/path/to/uitext")
)
let translated = try swedish.text(for: 152, key: 1)
```

New & Improved keeps its tables in `gamedata/uitext/<language>.dir`. Earlier versions
have one language in `gamedata/uitext.dir`. Pass an install's `gamedata` directory and
`UIText` uses whichever it has, preferring the language directory:

```swift
import Foundation

let install = UIText(gameData: URL(fileURLWithPath: "/path/to/gamedata"))
let french = UIText(gameData: URL(fileURLWithPath: "/path/to/gamedata"), language: "french")
```

This searches only the install, not the app bundle. With an earlier version, `language`
doesn't apply, and the catalog's `language` is `uitext`.

A game's own tables don't need a language directory. To read the tables kept directly in
a folder, pass the folder itself:

```swift
let ownText = UIText(directory: URL(fileURLWithPath: "/path/to/Interface/uitext"))
```

`UIText` is built for The Sims Online's tables, so it also:

- Reads UTF-8 and Windows-1252 files.
- Finds a value with no key of its own by its position among the table's values, from 0.
  A key written in the file always wins over a position.
- Follows a value that refers to an entry in another table, by one step.
- Reads each table once, so changes to a file after its first lookup aren't seen.

Use `table(for:)` to get a whole `CSTTable`, such as to read values in order or check
reported problems.

Missing file IDs, keys, and language directories return `*** MISSING ***`, which a
program can't tell from real text. `textIfPresent` finds the same text but returns
`nil` instead, including for a value that was never closed or a reference it can't
follow:

```swift
if let newMail = try english.textIfPresent(for: 101, key: "newMail", variables: 5) {
  print(newMail)
} else {
  print("Table 101 has no newMail.")
}
```

A wrapper that already holds its variables in an array can pass them with
`textIfPresent(for:key:with:)`. Don't pass an array to `variables:`, which takes it
as one variable.

Other filesystem errors are thrown to the caller.

Parsing and file lookup are synchronous. Async overloads remain temporarily
available for source compatibility and are deprecated.

### CSTDirectory and CSTLayers

`UIText` is built around The Sims Online. For other layouts, `CSTDirectory` reads every
table in one folder at once, named `#<id>#<name>.cst` as Sims Steering Committee writes
them, or `_<id>_<name>.cst`. It decodes UTF-8 and Windows-1252, ignores other files, and
never touches the disk again after it's created:

```swift
import Foundation

let global = try CSTDirectory(contentsOf: URL(fileURLWithPath: "/path/to/Global/Global.dir"))
let animations = global.table(for: 128)
```

`problems` lists any table ID that more than one file uses. The first file by name is
kept. You can also build one from tables in memory with `CSTDirectory(tables:)`.

`CSTLayers` looks through several directories in order, top layer first. Sims Steering
Committee lays each person's tables over the global ones this way, by position:

```swift
let ross = try CSTDirectory(contentsOf: URL(fileURLWithPath: "/path/to/Objects/ross.dir"))
let layers = CSTLayers([ross, global])

let animation = layers.value(inTable: 130, atPosition: 66)
let filledIn = layers.value(inTable: 130, atPosition: 20, treatingEmptyAsMissing: true)
```

A lookup moves to the next layer when a layer has no such table or value. An empty value
is returned as it is, unless you pass `treatingEmptyAsMissing: true`, because in most
tables an empty value is real empty text. Positions count every entry from 0, as
`CSTTable.entries` does. `layers` is a plain array, so adding or removing a layer, such as
a mod, changes nothing in the others. Look up keys and names with
`value(inTable:forKey:treatingEmptyAsMissing:)`.

These don't follow references between tables or fill placeholders. Use
`CST.format(_:with:)` for placeholders.
