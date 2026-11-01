import Foundation

@available(macOS 13, *)
struct RegexInterpolating: VariableInterpolating {
  private let placeholderPattern = try! Regex("%(?:(\\d+))?([sd])")

  func substitute(_ template: String, with variables: [String]) -> String {
    var result = ""
    var searchStartIndex = template.startIndex
    var variableIndex = 0

    for match in template.matches(of: placeholderPattern) {
      guard variableIndex < variables.count else {
        break
      }

      result.append(contentsOf: template[searchStartIndex..<match.range.lowerBound])
      let width = Int(match.output[1].substring ?? "") ?? 0
      let format = match.output[2].substring
      let variable = variables[variableIndex]
      result.append(contentsOf: format == "d" ? variable.padded(toWidth: width) : variable)

      searchStartIndex = match.range.upperBound
      variableIndex += 1
    }

    result.append(contentsOf: template[searchStartIndex...])
    return result
  }
}
