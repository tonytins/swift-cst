/// The values of a CST document in file order, and any problems found reading them.
///
/// Reading a table never fails. A malformed entry is reported in ``problems``, and the rest of the
/// table stays usable.
public struct CSTTable: Sendable {
  /// One value in the table, in the order it appears in the file.
  public struct Entry: Sendable, Equatable {
    /// The key written for this value, either before it on the same line or as a number alone on
    /// the nearest line above.
    ///
    /// A number followed by a period or colon, such as `1.label`, `5.`, or `1:`, gives the number
    /// alone as the key, in either place.
    public let key: String?

    /// Other text on the nearest line above this value. It may be a name that code looks up, or a
    /// note for translators. Nothing in the file separates the two.
    ///
    /// For a numbered key such as `1.new house window name`, this is the label after the
    /// separator, here `new house window name`, so a value can have both a key and a name.
    public let name: String?

    /// The text between the carets, or `nil` if the value was never closed.
    public let value: String?
  }

  /// Something wrong with the table that didn't stop it being read.
  public enum Problem: Sendable, Equatable {
    /// A value starting on this 1-based line was never closed.
    case unclosedValue(line: Int)

    /// This key already belongs to an earlier value, so the value on this 1-based line can't be
    /// looked up by it.
    case repeatedKey(String, line: Int)
  }

  /// Every value in the table in file order, including values that were never closed.
  public let entries: [Entry]

  /// The problems found while reading the table.
  public let problems: [Problem]

  private let entryIndexes: [String: Int]

  init(entries: [Entry], problems: [Problem]) {
    self.entries = entries
    self.problems = problems

    let closedIndexes = entries.indices.filter { entries[$0].value != nil }
    var entryIndexes: [String: Int] = [:]

    // Keys come first so that a key always wins over a name, whichever appears first in the file.
    for index in closedIndexes {
      guard let key = entries[index].key, entryIndexes[key] == nil else { continue }
      entryIndexes[key] = index
    }

    for index in closedIndexes {
      guard let name = entries[index].name, entryIndexes[name] == nil else { continue }
      entryIndexes[name] = index
    }

    self.entryIndexes = entryIndexes
  }
}

// MARK: - Public API

extension CSTTable {
  /// Creates a table from the text of a CST document.
  ///
  /// - Parameter content: The CST document to read.
  public init(_ content: String) {
    let scanner = TableScanner(content: content)
    self.init(entries: scanner.entries, problems: scanner.problems)
  }

  /// Returns the value for `key`, which can be a key or a name.
  ///
  /// If several values share a key, the first one is returned. Keys take priority over names.
  ///
  /// - Parameter key: The key or name to find.
  /// - Returns: The value, or `nil` if the table has no closed value for `key`.
  public func value(forKey key: some CustomStringConvertible) -> String? {
    entryIndexes[String(describing: key)].flatMap { entries[$0].value }
  }
}
