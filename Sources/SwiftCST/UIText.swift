import Foundation

/// Tables already read from disk, shared by copies of a `UIText`.
///
/// `NSLock` guards every access to `tables`, which is what makes `@unchecked Sendable` safe.
private final class LoadedTables: @unchecked Sendable {
  private let lock = NSLock()
  private var tables: [Int: CSTTable] = [:]

  subscript(id: Int) -> CSTTable? {
    get {
      lock.lock()
      defer { lock.unlock() }
      return tables[id]
    }
    set {
      lock.lock()
      defer { lock.unlock() }
      tables[id] = newValue
    }
  }
}

/// Looks up translated strings in language-specific CST files, the way The Sims Online does.
///
/// Each table is read once, so changes to a file after its first lookup aren't seen.
///
/// New & Improved keeps its tables in `gamedata/uitext/<language>.dir`. Earlier versions have one
/// language in `gamedata/uitext.dir`. `UIText(gameData:language:)` reads either.
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

  /// Creates a text catalog for an install's `gamedata` directory, in either layout.
  ///
  /// New & Improved's `uitext/<language>.dir` is used when it exists. Otherwise this reads the
  /// earlier single-language `uitext.dir`, where `language` doesn't apply, and ``language`` is
  /// `uitext`. Only the install is searched, not the app bundle. When neither directory exists,
  /// every lookup misses.
  ///
  /// - Parameters:
  ///   - gameData: The install's `gamedata` directory.
  ///   - language: The language directory name without the `.dir` suffix.
  public init(gameData: URL, language: String = "english") {
    let languages = gameData.appendingPathComponent("uitext", isDirectory: true)
    let languageDirectory = languages.appendingPathComponent("\(language).dir", isDirectory: true)

    if FileManager.default.fileExists(atPath: languageDirectory.path) {
      self.init(language: language, basePath: languages, fallbackPath: nil)
    } else {
      self.init(language: "uitext", basePath: gameData, fallbackPath: nil)
    }
  }

  let fallbackPath: URL?

  private let tables = LoadedTables()

  init(language: String, basePath: URL, fallbackPath: URL?) {
    self.language = language
    self.basePath = basePath
    self.fallbackPath = fallbackPath
  }

  /// Returns a localized string from the CST file whose name contains `id`.
  ///
  /// Files use the `_<id>_<name>.cst` naming convention. Missing files and keys
  /// return the same missing-message marker as `CST.parse`.
  ///
  /// A value with no key of its own can also be found by its position among the
  /// table's values, from 0. A value that refers to an entry in another table
  /// returns that entry's text.
  ///
  /// - Parameters:
  ///   - id: The numeric identifier in the CST filename.
  ///   - key: The entry key in the file.
  ///   - variables: Values used to fill the entry's placeholders in order. `%s`, `%d`, `%i`, `%u`,
  ///     and `%ld` take a variable. `%3d` pads with spaces, and `%03d` and `%.3d` with zeros.
  ///     `%%` becomes one percent sign.
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

  /// Returns a localized string from the CST file whose name contains `id`, or `nil` when it's
  /// missing.
  ///
  /// This finds the same text as ``text(for:key:variables:)``, which returns a marker instead of
  /// `nil`, so use this one when a program needs to tell a missing string from real text. It's
  /// `nil` when the table or key is missing, the value was never closed, or a reference's target is
  /// missing or is itself a reference.
  ///
  /// - Parameters:
  ///   - id: The numeric identifier in the CST filename.
  ///   - key: The entry key in the file, or a position for a value with no key of its own.
  ///   - variables: Values used to fill the entry's placeholders in order. `%s`, `%d`, `%i`, `%u`,
  ///     and `%ld` take a variable. `%3d` pads with spaces, and `%03d` and `%.3d` with zeros.
  ///     `%%` becomes one percent sign.
  /// - Throws: An error if the language directory or selected file cannot be read.
  /// - Returns: The localized entry, or `nil`.
  public func textIfPresent(
    for id: Int,
    key: some CustomStringConvertible,
    variables: any CustomStringConvertible...
  ) throws -> String? {
    try lookUpText(for: id, key: key, variables: variables)
  }

  /// Returns a localized string, or `nil` when it's missing, filling its placeholders from an
  /// array.
  ///
  /// This is ``textIfPresent(for:key:variables:)`` for a wrapper that already holds its variables
  /// in an array, which a variadic parameter can't take. It has its own label because Swift would
  /// otherwise pass the whole array to the variadic version as one variable.
  ///
  /// - Parameters:
  ///   - id: The numeric identifier in the CST filename.
  ///   - key: The entry key in the file, or a position for a value with no key of its own.
  ///   - variables: Values used to fill the entry's placeholders in order, as for
  ///     ``textIfPresent(for:key:variables:)``.
  /// - Throws: An error if the language directory or selected file cannot be read.
  /// - Returns: The localized entry, or `nil`.
  public func textIfPresent(
    for id: Int,
    key: some CustomStringConvertible,
    with variables: [any CustomStringConvertible]
  ) throws -> String? {
    try lookUpText(for: id, key: key, variables: variables)
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
  ///     and `%ld` take a variable. `%3d` pads with spaces, and `%03d` and `%.3d` with zeros.
  ///     `%%` becomes one percent sign.
  /// - Throws: An error if the language directory or selected file cannot be
  ///   read.
  /// - Returns: The localized entry, or the missing-message marker.
  @available(
    *, deprecated, message: "UIText file lookup is synchronous; use the synchronous overload."
  )
  public func text(
    for id: Int,
    key: some CustomStringConvertible,
    variables: any CustomStringConvertible...
  ) async throws -> String {
    try loadText(for: id, key: key, variables: variables)
  }

  /// Returns the table in the CST file whose name contains `id`.
  ///
  /// The first successful read is kept, so later lookups don't touch the disk. A table that isn't
  /// found is looked for again on the next call.
  ///
  /// - Parameter id: The numeric identifier in the CST filename.
  /// - Throws: An error if the language directory or selected file cannot be read.
  /// - Returns: The table, or `nil` if no file has this identifier.
  public func table(for id: Int) throws -> CSTTable? {
    if let table = tables[id] {
      return table
    }

    guard let fileURL = try fileURL(for: id) else {
      return nil
    }

    let table = CSTTable(Self.decoded(try Data(contentsOf: fileURL)))
    tables[id] = table
    return table
  }

  private func loadText(
    for id: Int,
    key: some CustomStringConvertible,
    variables: [any CustomStringConvertible]
  ) throws -> String {
    try lookUpText(for: id, key: key, variables: variables) ?? missingMessage
  }

  private func lookUpText(
    for id: Int,
    key: some CustomStringConvertible,
    variables: [any CustomStringConvertible]
  ) throws -> String? {
    try resolvedValue(inTable: id, key: String(describing: key))
      .map { CST.format($0, with: variables) }
  }

  /// Returns a value, following at most one reference so that a cycle can't hang a lookup.
  private func resolvedValue(inTable id: Int, key: String) throws -> String? {
    guard let value = try table(for: id).flatMap({ Self.value(in: $0, key: key) }) else {
      return nil
    }

    guard let target = Self.referenceTarget(in: value) else {
      return value
    }

    let targetValue = try table(for: target.table).flatMap { Self.value(in: $0, key: target.key) }
    return targetValue.flatMap { Self.referenceTarget(in: $0) == nil ? $0 : nil }
  }

  /// Returns the value for a key or name, or for a position among the table's values, from 0.
  ///
  /// A position only reaches a value with no key of its own. Names can't collide with positions,
  /// because a number on the line above a value is its key.
  private static func value(in table: CSTTable, key: String) -> String? {
    if let value = table.value(forKey: key) {
      return value
    }

    guard let position = Int(key), String(position) == key,
      table.entries.indices.contains(position), table.entries[position].key == nil
    else {
      return nil
    }

    return table.entries[position].value
  }

  /// Reads a reference such as `<cst><cst_id>276</cst_id><string_id>1</string_id></cst>`, which
  /// starts with a control character.
  private static func referenceTarget(in value: String) -> (table: Int, key: String)? {
    guard value.hasPrefix("\u{2}<cst>"),
      let table = enclosedText(in: value, tag: "cst_id").flatMap({ Int($0) }),
      let key = enclosedText(in: value, tag: "string_id")
    else {
      return nil
    }

    return (table, key)
  }

  private static func enclosedText(in value: String, tag: String) -> String? {
    guard let open = value.range(of: "<\(tag)>"),
      let close = value.range(of: "</\(tag)>", range: open.upperBound..<value.endIndex)
    else {
      return nil
    }

    return String(value[open.upperBound..<close.lowerBound])
  }

  /// Decodes a file as UTF-8, then as Windows-1252, the two encodings real tables use.
  ///
  /// A file that is neither still loads, with replacement characters for its invalid bytes.
  private static func decoded(_ data: Data) -> String {
    String(data: data, encoding: .utf8)
      ?? String(data: data, encoding: .windowsCP1252)
      ?? String(decoding: data, as: UTF8.self)
  }

  private func fileURL(for id: Int) throws -> URL? {
    for searchPath in [basePath] + [fallbackPath].compactMap({ $0 }) {
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

      if let fileURL =
        files
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
