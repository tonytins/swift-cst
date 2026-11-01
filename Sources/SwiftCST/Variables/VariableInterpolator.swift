struct VariableInterpolator {
  func substitute(_ template: String, with variables: [String]) -> String {
    var result = ""
    var index = template.startIndex
    var variableIndex = 0

    while index < template.endIndex {
      guard template[index] == "%" else {
        result.append(template[index])
        index = template.index(after: index)
        continue
      }

      let placeholderStart = index
      let formatStart = template.index(after: index)
      guard formatStart < template.endIndex else {
        result.append("%")
        break
      }

      var formatIndex = formatStart
      var widthDigits = ""

      while formatIndex < template.endIndex, template[formatIndex].isNumber {
        widthDigits.append(template[formatIndex])
        formatIndex = template.index(after: formatIndex)
      }

      guard formatIndex < template.endIndex else {
        result.append(contentsOf: template[placeholderStart...])
        break
      }

      let format = template[formatIndex]
      guard format == "s" || format == "d" else {
        result.append("%")
        index = formatStart
        continue
      }

      let placeholderEnd = template.index(after: formatIndex)
      guard variableIndex < variables.count else {
        result.append(contentsOf: template[placeholderStart..<placeholderEnd])
        index = placeholderEnd
        continue
      }

      let variable = variables[variableIndex]
      let width = Int(widthDigits) ?? 0
      result.append(contentsOf: format == "d" ? variable.padded(toWidth: width) : variable)

      variableIndex += 1
      index = placeholderEnd
    }

    return result
  }
}
