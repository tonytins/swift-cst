import Foundation

let missingMessage = "*** MISSING ***"

public struct CST {
  static var substitutor: VariableInterpolating {
    if #available(macOS 13, *) {
      RegexInterpolating()
    } else {
      LegacyInterpolating()
    }
  }

  static func scanAndBuild(
    _ content: String,
    key: some CustomStringConvertible,
    variables: any CustomStringConvertible...
  ) -> String {
    let ledger = Ledger(content: content)
    let entry = ledger.entries(forKey: String(describing: key))
    let stringVariables = variables.map { String(describing: $0) }

    return substitutor.substitute(entry, with: stringVariables)
  }
}

// MARK: - Public API

extension CST {

  public static func parse(
    _ content: String,
    key: some CustomStringConvertible,
    variables: any CustomStringConvertible...
  ) async -> String {
    return scanAndBuild(content, key: key, variables: variables)
  }

  @available(*, deprecated, message: "Use async version.")
  public static func parse(
    _ content: String,
    key: some CustomStringConvertible,
    variables: any CustomStringConvertible...
  ) -> String {
    return scanAndBuild(content, key: key, variables: variables)
  }

}
