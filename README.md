# 🔠 SwiftCST

SwiftCST is a library for parsing Maxis' key-value pair format. It can be used in conjunction with your own custom frameworks, or the original `UIText` APIs.

## What is CST?

Caret-Separated Text (or CST) is a key-value pair format represented by digits or words as keys and the value as text enclosed between carets. (e.g. `<key> ^<value>^`) This was used by The Sims Online to make translation easier.

In SwiftCST, C-style comments are supported. 

## Features

- [x] Variables
- [x] Multiline values
- [ ] UIText

### Limitations

In The Sims Online, it was possible to have keys on top of the value. At the moment, SwiftCST doesn't support this and excepts the key to be the same line as the caret.

Although all versions of my CST parser are designed with as much fault tolerance as possible, _that_ was an oversight on my part.

## Installation

```swift
let package = Package(
    // name, platforms, products, etc.
    dependencies: [
        // other dependencies
        .package(url: "https://github.com/tonytins/swift-cst.git", branch: "main"),
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

See the [documentation](docs/REMADE.md) for more info.

## Supported Versions

| swift-cst    | Minimum Swift Version |
| ------- | --------------------- |
| ``main`` | 6.0                   |

## License

I license this project under BSD-3-Clause license — see the [LICENSE](LICENSE) file for full text.
