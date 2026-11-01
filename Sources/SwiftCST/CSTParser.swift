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
  /// Parses the value for `key` and substitutes the supplied variables.
  ///
  /// - Parameters:
  ///   - content: The CST document to parse.
  ///   - key: The entry key to find.
  ///   - variables: Values used to replace `%s`, `%d`, and padded `%Nd`
  ///     placeholders.
  /// - Returns: The parsed value, or the missing-message marker.
  public static func parse(
    _ content: String,
    key: some CustomStringConvertible,
    variables: any CustomStringConvertible...
  ) -> String {
    parseContent(content, key: key, variables: variables)
  }

  /// Parses the value for `key` and substitutes the supplied variables.
  ///
  /// This operation is synchronous. This overload remains for source
  /// compatibility; use the synchronous overload instead.
  ///
  /// - Parameters:
  ///   - content: The CST document to parse.
  ///   - key: The entry key to find.
  ///   - variables: Values used to replace `%s`, `%d`, and padded `%Nd`
  ///     placeholders.
  /// - Returns: The parsed value, or the missing-message marker.
  @available(*, deprecated, message: "Parsing is synchronous; use the synchronous overload.")
  public static func parse(
    _ content: String,
    key: some CustomStringConvertible,
    variables: any CustomStringConvertible...
  ) async -> String {
    parseContent(content, key: key, variables: variables)
  }
}
