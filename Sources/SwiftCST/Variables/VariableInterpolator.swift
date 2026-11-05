struct VariableInterpolator {
  private struct Placeholder {
    let end: String.Index
    let isNumber: Bool
    let width: Int
  }

  func substitute(_ template: String, with variables: [String]) -> String {
    var result = ""
    var index = template.startIndex
    var remainingVariables = variables[...]

    while index < template.endIndex {
      guard template[index] == "%" else {
        result.append(template[index])
        index = template.index(after: index)
        continue
      }

      let afterPercent = template.index(after: index)
      if afterPercent < template.endIndex, template[afterPercent] == "%" {
        result.append("%")
        index = template.index(after: afterPercent)
        continue
      }

      guard let placeholder = placeholder(in: template, after: afterPercent) else {
        result.append("%")
        index = afterPercent
        continue
      }

      if let variable = remainingVariables.popFirst() {
        result.append(
          contentsOf: placeholder.isNumber ? variable.padded(toWidth: placeholder.width) : variable)
      } else {
        result.append(contentsOf: template[index..<placeholder.end])
      }

      index = placeholder.end
    }

    return result
  }

  /// Reads an optional `.`, a width, an optional `l`, and a conversion character.
  private func placeholder(in template: String, after percent: String.Index) -> Placeholder? {
    var rest = template[percent...]

    let hasPrecision = rest.first == "."
    if hasPrecision {
      rest = rest.dropFirst()
    }

    let digits = rest.prefix { $0.isASCII && $0.isNumber }
    rest = rest.dropFirst(digits.count)

    let hasLongModifier = rest.first == "l"
    if hasLongModifier {
      rest = rest.dropFirst()
    }

    guard let conversion = rest.first,
      (hasLongModifier ? "diu" : "sdiu").contains(conversion),
      !hasPrecision || !digits.isEmpty
    else {
      return nil
    }

    return Placeholder(
      end: template.index(after: rest.startIndex),
      isNumber: conversion != "s",
      width: Int(digits) ?? 0
    )
  }
}
