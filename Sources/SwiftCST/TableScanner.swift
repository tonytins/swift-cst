import Foundation

/// Reads a CST document into entries from whole lines, because comments only count at the start of
/// a line, while values run across lines.
struct TableScanner {
  private static let caret: Character = "^"

  private struct OpenValue {
    let key: String?
    let name: String?
    let line: Int
    var text: String
    var lastTextLine: String?
  }

  private(set) var entries: [CSTTable.Entry] = []
  private(set) var problems: [CSTTable.Problem] = []

  private var seenKeys: Set<String> = []
  private var lineAbove: String?
  private var openValue: OpenValue?

  init(content: String) {
    for (line, text) in Self.contentLines(of: content) {
      scan(text, line: line)
    }

    if let openValue {
      addUnclosedValue(openValue)
    }
  }

  /// Returns the lines that aren't comments, with their 1-based line numbers.
  private static func contentLines(of content: String) -> [(line: Int, text: String)] {
    var result: [(line: Int, text: String)] = []
    var isInBlockComment = false

    for (index, line) in normalized(content).components(separatedBy: "\n").enumerated() {
      let text = line.drop(while: \.isWhitespace)

      if isInBlockComment || text.hasPrefix("/*") {
        isInBlockComment = !line.contains("*/")
      } else if !text.hasPrefix("//"), !text.hasPrefix("#") {
        result.append((index + 1, line))
      }
    }

    return result
  }

  private static func normalized(_ content: String) -> String {
    var scalars = Substring(content).unicodeScalars
    if scalars.first == "\u{FEFF}" {
      scalars.removeFirst()
    }

    return String(Substring(scalars))
      .replacingOccurrences(of: "\r\n", with: "\n")
      .replacingOccurrences(of: "\r", with: "\n")
      .replacingOccurrences(of: "\u{2028}", with: "\n")
  }

  private mutating func scan(_ text: String, line: Int) {
    var rest = Substring(text)
    var hasValue = false

    if var open = openValue {
      guard let caret = rest.firstIndex(of: Self.caret) else {
        open.text += "\n" + rest
        let trimmed = rest.trimmingCharacters(in: .whitespaces)
        open.lastTextLine = trimmed.isEmpty ? open.lastTextLine : trimmed
        openValue = open
        return
      }

      openValue = nil

      if Self.holdsWholeEntry(rest) {
        // The next entry began before this value closed, so losing one value beats misreading
        // every entry after it. The last line read as part of the value may belong to the next one.
        addUnclosedValue(open)
        lineAbove = open.lastTextLine
      } else {
        addValue(open.text + "\n" + rest[..<caret], key: open.key, name: open.name, line: open.line)
        rest = rest[rest.index(after: caret)...]
        hasValue = true
      }
    }

    while let caret = rest.firstIndex(of: Self.caret) {
      hasValue = true
      let (key, name) = takeKeyAndName(before: rest[..<caret])
      let value = rest[rest.index(after: caret)...]

      guard let end = value.firstIndex(of: Self.caret) else {
        openValue = OpenValue(key: key, name: name, line: line, text: String(value))
        return
      }

      addValue(String(value[..<end]), key: key, name: name, line: line)
      rest = value[value.index(after: end)...]
    }

    // Text after a value on its line describes that value, not the next one.
    let trimmed = rest.trimmingCharacters(in: .whitespaces)
    if !hasValue, !trimmed.isEmpty {
      lineAbove = trimmed
    }
  }

  /// Returns whether a line holds an optional key and a whole value, and nothing after it.
  private static func holdsWholeEntry(_ line: Substring) -> Bool {
    guard line.filter({ $0 == caret }).count == 2, let last = line.lastIndex(of: caret) else {
      return false
    }

    return line[line.index(after: last)...].allSatisfy(\.isWhitespace)
  }

  private mutating func takeKeyAndName(before text: Substring) -> (key: String?, name: String?) {
    defer { lineAbove = nil }

    let key = text.trimmingCharacters(in: .whitespaces)
    guard key.isEmpty else {
      if let numbered = Self.numberedKey(key) {
        return (numbered.key, numbered.label)
      }
      return (key, nil)
    }

    guard let lineAbove else {
      return (nil, nil)
    }

    if lineAbove.allSatisfy(Self.isDigit) {
      return (lineAbove, nil)
    }
    if let numbered = Self.numberedKey(lineAbove) {
      return (numbered.key, numbered.label)
    }
    return (nil, lineAbove)
  }

  /// Splits a number followed by a period or colon, such as `1.new house window name`, `5.`, or
  /// `1:`, into the number as a key and the rest, if any, as a label.
  ///
  /// A digit right after the separator means the text is a number such as `1.5` or a time such as
  /// `10:30`, not a numbered key.
  private static func numberedKey(_ text: String) -> (key: String, label: String?)? {
    let digits = text.prefix(while: isDigit)
    guard !digits.isEmpty, let separator = text[digits.endIndex...].first,
      separator == "." || separator == ":"
    else {
      return nil
    }

    let rest = text[digits.endIndex...].dropFirst()
    guard rest.first.map(isDigit) != true else {
      return nil
    }

    let label = rest.trimmingCharacters(in: .whitespaces)
    return (String(digits), label.isEmpty ? nil : label)
  }

  private static func isDigit(_ character: Character) -> Bool {
    character.isASCII && character.isNumber
  }

  private mutating func addValue(_ value: String, key: String?, name: String?, line: Int) {
    entries.append(CSTTable.Entry(key: key, name: name, value: value))

    if let key, !seenKeys.insert(key).inserted {
      problems.append(.repeatedKey(key, line: line))
    }
  }

  private mutating func addUnclosedValue(_ open: OpenValue) {
    entries.append(CSTTable.Entry(key: open.key, name: open.name, value: nil))
    problems.append(.unclosedValue(line: open.line))
  }
}
