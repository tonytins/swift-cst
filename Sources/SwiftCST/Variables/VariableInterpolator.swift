struct VariableInterpolator {
  private struct Placeholder {
    let end: String.Index
    let padding: NumberPadding?
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
        result.append(contentsOf: placeholder.padding.map(variable.padded) ?? variable)
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

    let width = Int(digits) ?? 0
    let padding: NumberPadding =
      hasPrecision
      ? .digits(count: width)
      : digits.hasPrefix("0") ? .zeros(width: width) : .spaces(width: width)

    return Placeholder(
      end: template.index(after: rest.startIndex),
      padding: conversion == "s" ? nil : padding
    )
  }
}
