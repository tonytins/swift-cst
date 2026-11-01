# 🔠 SwiftCST

SwiftCST is a library for parsing Maxis' key-value pair format. It can be used with custom frameworks or the original `UIText` APIs.

## What is CST?

Caret-Separated Text (or CST) is a key-value pair format represented by digits or words as keys and the value as text enclosed between carets. (e.g. `<key> ^<value>^`) This was used by The Sims Online to make translation easier.

## Features

- [x] TSO compatible
    - [x] Keys above values
    - [x] Variables
- [x] Multiline values
- [x] C-style comments
- [x] UIText

## Editor Support

Basic VS Code syntax highlighting is available in [addons/vscode](addons/vscode/README.md).

### Key and value layout

Values can be placed on the same line as their key or on the following line. Multiline values are supported in both layouts.

### Comments and malformed values

Whole-line `//` and `#` comments are ignored. Block comments beginning with
`/*` are ignored through the line containing `*/`. These comment lines are also
ignored inside multiline values.

An unterminated value is treated as missing if another entry begins before its
closing caret. This prevents a malformed entry from consuming later entries.

## Installation

```swift
let package = Package(
    // name, platforms, products, etc.
    dependencies: [
        // other dependencies
        .package(url: "https://github.com/tonytins/swift-cst.git", from: "0.1.0"),
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

#### UIText

`UIText` looks up a key in a language directory containing files named
`_<id>_<name>.cst`. By default it first searches an `uitext` directory beside
the running executable, then falls back to the app bundle's `uitext` resources.
A different first-choice directory can be provided with `basePath`; the bundle
lookup remains the fallback.

```swift
let text = UIText(language: "english")
let greeting = try text.text(for: 154, key: 1)

print(greeting)
```

Missing file IDs and keys return `*** MISSING ***`. Filesystem errors, such as
a missing language directory, are thrown to the caller.

Parsing and file lookup are synchronous. Async overloads remain temporarily
available for source compatibility and are deprecated.

## Supported Versions

| swift-cst    | Minimum Swift Version |
| ------- | --------------------- |
| ``0.1.0 ...`` | 6.3                   |

## License

I license this project under BSD-3-Clause license — see the [LICENSE](LICENSE) file for full text.
