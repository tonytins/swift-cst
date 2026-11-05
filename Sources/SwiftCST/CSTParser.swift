import Foundation

let missingMessage = "*** MISSING ***"

public struct CST {
  private static func parseContent(
    _ content: String,
    key: some CustomStringConvertible,
    variables: [any CustomStringConvertible]
  ) -> String {
    format(CSTTable(content).value(forKey: key) ?? missingMessage, with: variables)
  }
}

// MARK: - Public API

extension CST {
  /// Fills a value's placeholders, for code that reads values from a ``CSTTable``.
  ///
  /// A placeholder with no variable left stays as written, so a mistake is visible, and any other
  /// use of `%` is left alone.
  ///
  /// - Parameters:
  ///   - value: The text to fill.
  ///   - variables: Values used to fill the placeholders in order. `%s`, `%d`, `%i`, `%u`, and `%ld`
  ///     take a variable, and `%03d`, `%3d`, and `%.3d` pad it with zeros. `%%` becomes one percent
  ///     sign.
  /// - Returns: The filled text.
  public static func format(
    _ value: String,
    with variables: [any CustomStringConvertible]
  ) -> String {
    VariableInterpolator().substitute(value, with: variables.map { String(describing: $0) })
  }

  /// Parses the value for `key` and substitutes the supplied variables.
  ///
  /// - Parameters:
  ///   - content: The CST document to parse.
  ///   - key: The entry key to find.
  ///   - variables: Values used to fill the value's placeholders in order. `%s`, `%d`, `%i`, `%u`,
  ///     and `%ld` take a variable, and `%03d`, `%3d`, and `%.3d` pad it with zeros. `%%` becomes
  ///     one percent sign.
  /// - Returns: The parsed value, or the missing-message marker. Use ``CSTTable`` to tell a missing
  ///   value from real text.
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
  ///   - variables: Values used to fill the value's placeholders in order. `%s`, `%d`, `%i`, `%u`,
  ///     and `%ld` take a variable, and `%03d`, `%3d`, and `%.3d` pad it with zeros. `%%` becomes
  ///     one percent sign.
  /// - Returns: The parsed value, or the missing-message marker. Use ``CSTTable`` to tell a missing
  ///   value from real text.
  @available(*, deprecated, message: "Parsing is synchronous; use the synchronous overload.")
  public static func parse(
    _ content: String,
    key: some CustomStringConvertible,
    variables: any CustomStringConvertible...
  ) async -> String {
    parseContent(content, key: key, variables: variables)
  }
}
