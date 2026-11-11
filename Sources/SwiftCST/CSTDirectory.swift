import Foundation

/// The tables kept as loose files in one directory, read all at once.
///
/// Each table is a file named `#<id>#<name>.cst`, as Sims Steering Committee writes them in
/// folders such as `Global.dir`, or `_<id>_<name>.cst`, as The Sims Online does. Other files are
/// ignored. Every table is read when the directory is, so a `CSTDirectory` is a plain value that
/// never touches the disk again.
///
/// To look through several directories in order, such as a person's tables over the global ones,
/// use ``CSTLayers``.
public struct CSTDirectory: Sendable {
  /// Something wrong with the directory that didn't stop it being read.
  public enum Problem: Sendable, Equatable {
    /// Another file already has this table ID, so the file with this name was skipped. Files are
    /// read in order of their names, so the first name wins.
    case repeatedTable(Int, file: String)
  }

  /// The tables by their IDs.
  public let tables: [Int: CSTTable]

  /// The problems found while reading the directory. Problems inside a table are in that table's
  /// ``CSTTable/problems``.
  public let problems: [Problem]

  /// Creates a directory from tables already in memory, such as tables a program builds itself.
  ///
  /// - Parameter tables: The tables by their IDs.
  public init(tables: [Int: CSTTable]) {
    self.tables = tables
    self.problems = []
  }

  /// Reads every table in a directory.
  ///
  /// A file is decoded as UTF-8, then as Windows-1252, the two encodings real tables use. Reading a
  /// table never fails, so the only errors are a directory or file that can't be read.
  ///
  /// - Parameter directory: The directory holding the tables. Subdirectories aren't searched.
  /// - Throws: An error if the directory or one of its tables can't be read.
  public init(contentsOf directory: URL) throws {
    let files = try FileManager.default.contentsOfDirectory(
      at: directory,
      includingPropertiesForKeys: nil,
      options: [.skipsHiddenFiles]
    )
    .sorted { $0.lastPathComponent < $1.lastPathComponent }

    var tables: [Int: CSTTable] = [:]
    var problems: [Problem] = []

    for file in files {
      guard let id = Self.tableID(fromFileName: file.lastPathComponent) else {
        continue
      }
      guard tables[id] == nil else {
        problems.append(.repeatedTable(id, file: file.lastPathComponent))
        continue
      }

      tables[id] = CSTTable(decodedTableText(try Data(contentsOf: file)))
    }

    self.tables = tables
    self.problems = problems
  }

  /// Returns the table with this ID, or `nil` if the directory has none.
  ///
  /// - Parameter id: The table's ID.
  public func table(for id: Int) -> CSTTable? {
    tables[id]
  }

  /// Returns the ID in a file name such as `#128#Animations.cst` or `_101_strings.cst`, or `nil`
  /// if the name follows neither pattern.
  static func tableID(fromFileName fileName: String) -> Int? {
    let url = URL(fileURLWithPath: fileName)
    guard url.pathExtension.caseInsensitiveCompare("cst") == .orderedSame else {
      return nil
    }

    let name = url.deletingPathExtension().lastPathComponent
    guard let separator = name.first, separator == "#" || separator == "_" else {
      return nil
    }

    let id = name.dropFirst().prefix { $0 != separator }
    guard id.endIndex < name.endIndex, !id.isEmpty, id.allSatisfy({ $0.isASCII && $0.isNumber })
    else {
      return nil
    }

    return Int(id)
  }
}

/// Decodes a table's file as UTF-8, then as Windows-1252, the two encodings real tables use.
///
/// A file that is neither still loads, with replacement characters for its invalid bytes.
func decodedTableText(_ data: Data) -> String {
  String(data: data, encoding: .utf8)
    ?? String(data: data, encoding: .windowsCP1252)
    ?? String(decoding: data, as: UTF8.self)
}
