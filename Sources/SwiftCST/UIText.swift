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
  ///     this is an `uitext` directory beside the running executable. The app
  ///     bundle's `uitext` resources are searched afterward.
  public init(
    language: String = "english",
    basePath: URL? = nil
  ) {
    let executableDirectory =
      Bundle.main.executableURL?.deletingLastPathComponent()
      ?? URL(
        fileURLWithPath: FileManager.default.currentDirectoryPath,
        isDirectory: true
      )

    self.init(
      language: language,
      basePath: basePath
        ?? executableDirectory.appendingPathComponent("uitext", isDirectory: true),
      fallbackPath: (Bundle.main.resourceURL ?? Bundle.main.bundleURL)
        .appendingPathComponent("uitext", isDirectory: true)
    )
  }

  let fallbackPath: URL

  init(language: String, basePath: URL, fallbackPath: URL) {
    self.language = language
    self.basePath = basePath
    self.fallbackPath = fallbackPath
  }

  /// Returns a localized string from the CST file whose name contains `id`.
  ///
  /// Files use the `_<id>_<name>.cst` naming convention. Missing files and keys
  /// return the same missing-message marker as `CST.parse`.
  ///
  /// - Parameters:
  ///   - id: The numeric identifier in the CST filename.
  ///   - key: The entry key in the file.
  ///   - variables: Values used to fill the entry's placeholders in order. `%s`, `%d`, `%i`, `%u`,
  ///     and `%ld` take a variable, and `%03d`, `%3d`, and `%.3d` pad it with zeros. `%%` becomes
  ///     one percent sign.
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
  ///   - variables: Values used to fill the entry's placeholders in order. `%s`, `%d`, `%i`, `%u`,
  ///     and `%ld` take a variable, and `%03d`, `%3d`, and `%.3d` pad it with zeros. `%%` becomes
  ///     one percent sign.
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
    for searchPath in [basePath, fallbackPath] {
      let languageDirectory = searchPath.appendingPathComponent(
        "\(language).dir",
        isDirectory: true
      )
      guard FileManager.default.fileExists(atPath: languageDirectory.path) else {
        continue
      }

      let files = try FileManager.default.contentsOfDirectory(
        at: languageDirectory,
        includingPropertiesForKeys: nil,
        options: [.skipsHiddenFiles]
      )

      if let fileURL = files
        .sorted(by: { $0.lastPathComponent < $1.lastPathComponent })
        .first(where: { fileURL in
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
        })
      {
        return fileURL
      }
    }

    return nil
  }
}
