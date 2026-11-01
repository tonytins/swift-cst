import Foundation

struct Ledger {
  private static let caret: Character = "^"

  let lines: [String]

  init(content: String) {
    let normalized = content
      .replacingOccurrences(of: "\r\n", with: "\n")
      .replacingOccurrences(of: "\r", with: "\n")
      .replacingOccurrences(of: "\u{2028}", with: "\n")
    self.lines = Self.removingComments(from: normalized.components(separatedBy: "\n"))
  }

  private static func removingComments(from lines: [String]) -> [String] {
    var isInsideBlockComment = false
    var contentLines: [String] = []

    for line in lines {
      let trimmedLine = line.trimmingCharacters(in: .whitespaces)

      if isInsideBlockComment {
        if trimmedLine.contains("*/") {
          isInsideBlockComment = false
        }
        continue
      }

      if trimmedLine.hasPrefix("//") || trimmedLine.hasPrefix("#") {
        continue
      }

      if trimmedLine.hasPrefix("/*") {
        isInsideBlockComment = !trimmedLine.contains("*/")
        continue
      }

      if trimmedLine.hasSuffix("*/") {
        continue
      }

      contentLines.append(line)
    }

    return contentLines
  }

  private func keyEnds(at index: String.Index, in line: String) -> Bool {
    guard index < line.endIndex else {
      return true
    }

    return line[index].isWhitespace || line[index] == Self.caret
  }

  private func isEntryStart(at lineIndex: Int) -> Bool {
    let line = lines[lineIndex]
    let content = line.drop(while: \.isWhitespace)

    if let caretIndex = content.firstIndex(of: Self.caret) {
      let rawKey = content[..<caretIndex]
      let key = rawKey.trimmingCharacters(in: .whitespaces)
      guard !key.isEmpty, !key.contains(where: \.isWhitespace) else {
        return false
      }

      let valueStart = content.index(after: caretIndex)
      return rawKey.last?.isWhitespace == true
        || (valueStart < content.endIndex && content[valueStart] != Self.caret)
    }

    guard !content.isEmpty, !content.contains(where: \.isWhitespace),
      lineIndex + 1 < lines.count
    else {
      return false
    }

    return lines[lineIndex + 1].drop(while: \.isWhitespace).first == Self.caret
  }

  private func value(
    startingAt lineIndex: Int,
    caretIndex: String.Index
  ) -> String? {
    var value = String(lines[lineIndex][lines[lineIndex].index(after: caretIndex)...])

    if let end = value.firstIndex(of: Self.caret) {
      return String(value[..<end])
    }

    for nextLineIndex in (lineIndex + 1)..<lines.count {
      if isEntryStart(at: nextLineIndex) {
        return nil
      }

      let line = lines[nextLineIndex]
      value.append("\n")

      if let end = line.firstIndex(of: Self.caret) {
        value.append(contentsOf: line[..<end])
        return value
      }

      value.append(contentsOf: line)
    }

    return nil
  }

  func entries(forKey key: String) -> String {
    for (lineIndex, line) in lines.enumerated() {
      guard line.hasPrefix(key) else {
        continue
      }

      let keyEnd = line.index(line.startIndex, offsetBy: key.count)
      guard keyEnds(at: keyEnd, in: line) else {
        continue
      }

      if let caretIndex = line[keyEnd...].firstIndex(of: Self.caret) {
        if let value = value(startingAt: lineIndex, caretIndex: caretIndex) {
          return value
        }

        continue
      }

      guard line[keyEnd...].allSatisfy(\.isWhitespace), lineIndex + 1 < lines.count else {
        continue
      }

      let nextLine = lines[lineIndex + 1]
      let nextLineContent = nextLine.drop(while: \.isWhitespace)
      guard nextLineContent.first == Self.caret,
        let caretIndex = nextLineContent.firstIndex(of: Self.caret)
      else {
        continue
      }

      if let value = value(startingAt: lineIndex + 1, caretIndex: caretIndex) {
        return value
      }
    }

    return missingMessage
  }

}
