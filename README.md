# 🔠 SwiftCST

SwiftCST is a library for parsing Maxis' key-value pair format. It can be used in conjunction with your own custom frameworks, or the original `UIText` APIs.

Caret-Separated Text (or CST) is a key-value pair format represented by digits or words as keys and the value as text enclosed between carets. (e.g. `<key> ^<text>^`) Any text which is not enclosed with carets is considered a comment and ignored. Neither strings nor comments may use the caret character.

## Features

- [x] Native support for Sims Online's `.cst` files.
- [x] Variable support
- [ ] UIText Support

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
let content = "1 ^Hello %s!^"
let helloWorld = CST.parse(cst, key: 1, variables: "World")

print(helloworld)
```

### Supported Versions

| act2    | Minimum Swift Version |
| ------- | --------------------- |
| ``main`` | 6.0                   |

## License

I license this project under BSD-3-Clause license — see the [LICENSE](LICENSE) file for full text.
