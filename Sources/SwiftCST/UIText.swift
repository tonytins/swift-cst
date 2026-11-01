import Foundation

/// Looks up translated strings in language-specific CST files.
public struct UIText: Sendable {
  /// The language directory to search, such as `english.dir`.
  public let language: String

  /// The directory containing the language directories.
  public let basePath: URL

  /// Creates a text catalog.
  ///
  /// - Parameters:
  ///   - language: The language directory name without the `.dir` suffix.
  ///   - basePath: The directory containing language directories. By default,
  ///     this is an `uitext` directory in the application bundle's resources.
  public init(
    language: String = "english",
    basePath: URL? = nil
  ) {
    self.language = language
    self.basePath =
      basePath
      ?? (Bundle.main.resourceURL ?? Bundle.main.bundleURL)
        .appendingPathComponent("uitext", isDirectory: true)
  }

  /// Returns a localized string from the CST file whose name contains `id`.
  ///
  /// Files use the `_<id>_<name>.cst` naming convention. Missing files and keys
  /// return the same missing-message marker as `CST.parse`.
  ///
  /// - Parameters:
  ///   - id: The numeric identifier in the CST filename.
  ///   - key: The entry key in the file.
  ///   - variables: Values used to replace `%s`, `%d`, and padded `%Nd`
  ///     placeholders in the entry.
  /// - Throws: An error if the language directory or selected file cannot be
  ///   read.
  /// - Returns: The localized entry, or the missing-message marker.
  public func text(
    for id: Int,
    key: some CustomStringConvertible,
    variables: any CustomStringConvertible...
  ) throws -> String {
    try loadText(for: id, key: key, variables: variables)
  }

  /// Asynchronously named compatibility overload for localized text lookup.
  ///
  /// File discovery and reading are synchronous. Use the synchronous overload
  /// instead.
  ///
  /// - Parameters:
  ///   - id: The numeric identifier in the CST filename.
  ///   - key: The entry key in the file.
  ///   - variables: Values used to replace `%s`, `%d`, and padded `%Nd`
  ///     placeholders in the entry.
  /// - Throws: An error if the language directory or selected file cannot be
  ///   read.
  /// - Returns: The localized entry, or the missing-message marker.
  @available(*, deprecated, message: "UIText file lookup is synchronous; use the synchronous overload.")
  public func text(
    for id: Int,
    key: some CustomStringConvertible,
    variables: any CustomStringConvertible...
  ) async throws -> String {
    try loadText(for: id, key: key, variables: variables)
  }

  private func loadText(
    for id: Int,
    key: some CustomStringConvertible,
    variables: [any CustomStringConvertible]
  ) throws -> String {
    guard let fileURL = try fileURL(for: id) else {
      return missingMessage
    }

    let content = try String(contentsOf: fileURL, encoding: .utf8)
    return CST.parse(content, key: key, variables: variables)
  }

  private func fileURL(for id: Int) throws -> URL? {
    let languageDirectory = basePath.appendingPathComponent(
      "\(language).dir",
      isDirectory: true
    )
    let files = try FileManager.default.contentsOfDirectory(
      at: languageDirectory,
      includingPropertiesForKeys: nil,
      options: [.skipsHiddenFiles]
    )

    return files
      .sorted { $0.lastPathComponent < $1.lastPathComponent }
      .first { fileURL in
        guard fileURL.pathExtension.caseInsensitiveCompare("cst") == .orderedSame else {
          return false
        }

        let filename = fileURL.deletingPathExtension().lastPathComponent
        guard filename.first == "_",
          let idEnd = filename.dropFirst().firstIndex(of: "_")
        else {
          return false
        }

        return filename[filename.index(after: filename.startIndex)..<idEnd] == String(id)
      }
  }
}
