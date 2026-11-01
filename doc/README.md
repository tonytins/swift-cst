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

Whole-line `//` and `#` comments are ignored. Block comments beginning with
`/*` are ignored through the line containing `*/`. These comment lines are also
ignored inside multiline values. An unterminated value does not consume later
entries.

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

Missing file IDs and keys return `*** MISSING ***`. Filesystem errors are
thrown to the caller.

Parsing and file lookup are synchronous. Async overloads remain temporarily
available for source compatibility and are deprecated.
