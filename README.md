# 🔠 SwiftCST

SwiftCST is a library for asynchronously parsing Maxis' key-value pair format. It can be used in conjunction with your own custom frameworks, or the original `UIText` APIs.

## What is CST?

Caret-Separated Text (or CST) is a key-value pair format represented by digits or words as keys and the value as text enclosed between carets. (e.g. `<key> ^<value>^`) This was used by The Sims Online to make translation easier.

## Features

- [x] TSO compatible
    - [x] Keys above values
    - [x] Variables
- [x] Multiline values
- [x] C-style comments
- [x] Asynchronous support
- [x] UIText

### Key and value layout

Values can be placed on the same line as their key or on the following line. Multiline values are supported in both layouts.

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
let helloWorld = await CST.parse(content, key: 1, variables: "World")

print(helloWorld)
```

#### UIText

`UIText` looks up a key in a language directory containing files named
`_<id>_<name>.cst`. The package includes an English catalog. Other catalogs can
be supplied by passing the directory that contains language directories, such
as `english.dir`, as `basePath`.

```swift
let text = UIText(language: "english")
let greeting = try await text.text(for: 154, key: 1)

print(greeting)
```

Missing file IDs and keys return `*** MISSING ***`. Filesystem errors, such as
a missing language directory, are thrown to the caller.

## Supported Versions

| swift-cst    | Minimum Swift Version |
| ------- | --------------------- |
| ``0.1.0 ...`` | 6.3                   |

## License

I license this project under BSD-3-Clause license — see the [LICENSE](LICENSE) file for full text.
