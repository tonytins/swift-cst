# 🔠 SwiftCST

SwiftCST is a library for parsing Maxis' key-value pair format. It can be used with custom frameworks or the original `UIText` APIs.

## What is CST?

Caret-Separated Text (or CST) is a key-value pair format represented by digits or words as keys and the value as text enclosed between carets. (e.g. `<key> ^<value>^`) This was used by The Sims Online to make translation easier.

## Features

- [x] TSO compatible, checked against the beta, base game, and New & Improved
    - [x] Values with no key, and names above values
    - [x] Keys with spaces, and indented keys
    - [x] Variables
    - [x] UTF-8 and Windows-1252 files
    - [x] References between tables
- [x] Multiline values
- [x] C-style comments
- [x] Malformed entries reported rather than stopping the read
- [x] UIText

The format is described in [the CST specification](doc/CST.md).

## Editor Support

Basic VS Code syntax highlighting is available in [addons/vscode](addons/vscode/README.md).

### Key and value layout

Values can be placed on the same line as their key or on a later line. Blank lines and comments between them don't matter, and multiline values are supported in both layouts. A key must match whole, so `ok` doesn't find `ok button`.

### Comments and malformed values

Whole-line `//` and `#` comments are ignored. Block comments beginning with
`/*` are ignored through the line containing `*/`. These comment lines are also
ignored inside multiline values.

An unterminated value is treated as missing if a line holding a whole entry comes
before its closing caret. This prevents a malformed entry from consuming later
entries. `CSTTable` reports these in its `problems`.

## Installation

```swift
let package = Package(
    // name, platforms, products, etc.
    dependencies: [
        // other dependencies
        .package(url: "https://github.com/tonytins/swift-cst.git", from: "0.2.0"),
    ],
    targets: [
        .executableTarget(name: "<your-game>", dependencies: [
            // other dependencies
            .product(name: "SwiftCST", package: "swift-cst"),
        ]),
        // other targets
    ]
)
```

Or in Xcode: File -> Add Package Dependencies, then paste the repo URL.

#### Usage

```swift
let content = "1 ^Hello %s!^" // %s represents a string variable
let helloWorld = CST.parse(content, key: 1, variables: "World")

print(helloWorld)
```

`CST.parse` returns `*** MISSING ***` for a missing key. To tell that apart from
real text, or to look up many keys without reading the document each time, use
`CSTTable`:

```swift
let table = CSTTable(content)

if let hello = table.value(forKey: 1) {
    print(CST.format(hello, with: ["World"]))
}

print(table.entries.count) // Every value, in file order
print(table.problems) // Anything malformed
```

#### UIText

`UIText` looks up a key in a language directory containing files named
`_<id>_<name>.cst`, the way The Sims Online does. It reads UTF-8 and Windows-1252
files, finds values with no key by their position from 0, and follows references
between tables. By default it first searches an `uitext` directory beside the
running executable, then falls back to the app bundle's `uitext` resources. A
different first-choice directory can be provided with `basePath`; the bundle lookup
remains the fallback.

```swift
let text = UIText(language: "english")
let greeting = try text.text(for: 154, key: 1)

print(greeting)
```

Each table is read once, so changes to a file after its first lookup aren't seen.

Missing file IDs, keys, and language directories return `*** MISSING ***`. Other
filesystem errors are thrown to the caller.

Parsing and file lookup are synchronous. Async overloads remain temporarily
available for source compatibility and are deprecated.

## Supported Versions

| swift-cst    | Minimum Swift Version |
| ------- | --------------------- |
| ``0.1.0 ...`` | 6.3                   |

## License

I license this project under BSD-3-Clause license — see the [LICENSE](LICENSE) file for full text.
