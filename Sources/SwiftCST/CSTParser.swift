import Foundation

let missingMessage = "*** MISSING ***"

public struct CST {
  private static func parseContent(
    _ content: String,
    key: some CustomStringConvertible,
    variables: [any CustomStringConvertible]
  ) -> String {
    let ledger = Ledger(content: content)
    let entry = ledger.entries(forKey: String(describing: key))
    let stringVariables = variables.map { String(describing: $0) }

    return VariableInterpolator().substitute(entry, with: stringVariables)
  }
}

// MARK: - Public API

extension CST {

  public static func parse(
    _ content: String,
    key: some CustomStringConvertible,
    variables: any CustomStringConvertible...
  ) async -> String {
    parseContent(content, key: key, variables: variables)
  }

  @available(*, deprecated, message: "Use async version.")
  public static func parse(
    _ content: String,
    key: some CustomStringConvertible,
    variables: any CustomStringConvertible...
  ) -> String {
    parseContent(content, key: key, variables: variables)
  }

}
