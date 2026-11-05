# SwiftCST

SwiftCST is a library for parsing Maxis' key-value pair format.

## What is CST?

Caret-Separated Text (or CST) is a key-value pair format represented by digits or words as keys and the value as text enclosed between carets. (e.g. `<key> ^<value>^`) This was used by The Sims Online to make translation easier.

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
have one language in `gamedata/uitext.dir`, which you can read by passing `uitext` as
the language and `gamedata` as the base path:

```swift
import Foundation

let baseGame = UIText(
  language: "uitext",
  basePath: URL(fileURLWithPath: "/path/to/gamedata")
)
```

`UIText` is built for The Sims Online's tables, so it also:

- Reads UTF-8 and Windows-1252 files.
- Finds a value with no key of its own by its position among the table's values, from 0.
  A key written in the file always wins over a position.
- Follows a value that refers to an entry in another table, by one step.
- Reads each table once, so changes to a file after its first lookup aren't seen.

Use `table(for:)` to get a whole `CSTTable`, such as to read values in order or check
reported problems.

Missing file IDs, keys, and language directories return `*** MISSING ***`. Other
filesystem errors are thrown to the caller.

Parsing and file lookup are synchronous. Async overloads remain temporarily
available for source compatibility and are deprecated.
