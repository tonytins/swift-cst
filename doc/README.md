# SwiftCST

SwiftCST is a library for asynchronously parsing Maxis' key-value text format.

## What Is CST?

Caret-Separated Text (or CST) is a key-value pair format represented by digits or words as keys and the value as text enclosed between carets. (e.g. `<key> ^<value>^`) 

The format was originally used for The Sims Online to make translation into other languages easier.

## Usage

Basic parsing is straight forward. 

```swift
let quickFox = "1 ^The quick brown fox jumps over the lazy dog.^"
let cst = await CST.parse(content, key: 1)

print(cst)
```

### Variables

You may need to parse one or more variables.

```swift
let quickFox = "1 ^The quick brown fox %s over the lazy dog.^" // %s represents a string variable
let cst = await CST.parse(quickFox, key: 1, variables: "leaps")


print(cst)
```

### Keys

You are not limited to numbers as keys. In fact, both text, and even emojis are valid.

```swift
// %d represents digits.
let input = """
🦊 ^The quick brown fox %s over the lazy dog.^
mail ^You have %d new messages^
"""

let quickFox = await CST.parse(input, key: "🦊", variables: "leaps")
let mail = await CST.parse(input, key: "mail", variables: 5)

let output = """
\(quickFox)
\(mail)
"""

print(output)
```

<!--
### In Production

```csharp
#r "nuget:CSTNet,2.0.103"
using CSTNet;

var english = new UIText(); // UIText assumes English
var swedish = new UIText("swedish");
var engExample = english.GetText(152, 1); // english.dir/_154_miscstrings.cst
var sweExample = swedish.GetText(152, 1); // swedish.dir/_154_miscstrings.cst

Console.WriteLine(engExample);
Console.WriteLine(sweExample);
```
-->
