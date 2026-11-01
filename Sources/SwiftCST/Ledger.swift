import Foundation

struct Ledger {
  private static let caret: Character = "^"

  let lines: [String]

  init(content: String) {
    let normalized = content
      .replacingOccurrences(of: "\r\n", with: "\n")
      .replacingOccurrences(of: "\r", with: "\n")
      .replacingOccurrences(of: "\u{2028}", with: "\n")
    self.lines = normalized.components(separatedBy: "\n")
  }

  private func isComment(_ line: String) -> Bool {
    let line = line.trimmingCharacters(in: .whitespaces)
    return line.hasPrefix("//") || line.hasPrefix("#") || line.hasPrefix("/*")
      || line.hasSuffix("*/")
  }

  private func keyEnds(at index: String.Index, in line: String) -> Bool {
    guard index < line.endIndex else {
      return true
    }

    return line[index].isWhitespace || line[index] == Self.caret
  }

  private func value(
    startingAt lineIndex: Int,
    caretIndex: String.Index
  ) -> String? {
    var value = String(lines[lineIndex][lines[lineIndex].index(after: caretIndex)...])

    if let end = value.firstIndex(of: Self.caret) {
      return String(value[..<end])
    }

    for line in lines.dropFirst(lineIndex + 1) {
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
      guard !isComment(line), line.hasPrefix(key) else {
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
