import Foundation
import Testing

@testable import SwiftCST

/// Returns the example from the specification page, so the page and the tests can't drift apart.
func specificationExample(filePath: String = #filePath) throws -> String {
  let page = URL(fileURLWithPath: filePath)
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .appendingPathComponent("doc/CST.md")
  let text = try String(contentsOf: page, encoding: .utf8)
  let marker = try #require(text.range(of: "<!-- The specification example. -->"))
  let open = try #require(text.range(of: "```text\n", range: marker.upperBound..<text.endIndex))
  let close = try #require(text.range(of: "\n```", range: open.upperBound..<text.endIndex))

  return String(text[open.upperBound..<close.lowerBound])
}

struct CSTTableTests {
  private typealias Entry = CSTTable.Entry

  @Test
  func readsSpecificationExample() throws {
    let document = try specificationExample()

    let expected = [
      Entry(key: "1", name: nil, value: "A value after its key"),
      Entry(key: "2", name: nil, value: "An indented key"),
      Entry(key: "3", name: nil, value: "A key above its value"),
      Entry(key: "4", name: nil, value: "A value that runs\nacross lines"),
      Entry(key: "ok button", name: nil, value: "A key with spaces"),
      Entry(key: nil, name: "kErrNoFood", value: "A name above its value"),
      Entry(key: nil, name: "A note for translators.", value: "A value with a note above it"),
      Entry(key: nil, name: nil, value: "A value on its own"),
      Entry(key: nil, name: nil, value: "Another value on its own"),
    ]

    let table = CSTTable(document)

    #expect(table.entries == expected)
    #expect(table.problems.isEmpty)
  }

  @Test(arguments: ["\r\n", "\r", "\n", "\u{2028}"])
  func readsEveryLineEnding(lineEnding: String) {
    let table = CSTTable(["1 ^a", "b^", "2", "^c^"].joined(separator: lineEnding))

    #expect(table.value(forKey: 1) == "a\nb")
    #expect(table.value(forKey: 2) == "c")
  }

  @Test
  func ignoresAByteOrderMark() {
    #expect(CSTTable("\u{FEFF}1 ^one^").value(forKey: 1) == "one")
  }

  @Test
  func blankLinesAndCommentsDoNotSeparateAKeyFromItsValue() {
    let table = CSTTable(
      """
      3

      // A comment.
      ^three^
      """
    )

    #expect(table.value(forKey: 3) == "three")
  }

  @Test(arguments: ["ok", "24", ""])
  func keyMustMatchWhole(key: String) {
    let table = CSTTable(
      """
      ok button ^button^
      24 012 ^reason^
      ^keyless^
      """
    )

    #expect(table.value(forKey: key) == nil)
  }

  @Test
  func textAfterAClosingCaretIsNotTheNextValuesName() {
    let table = CSTTable(
      """
      ^one line^ a note
      ^two
      lines^ another note
      ^last^
      """
    )

    #expect(table.entries.map(\.name) == [nil, nil, nil])
    #expect(table.entries.map(\.value) == ["one line", "two\nlines", "last"])
  }

  @Test
  func keepsEmptyValues() {
    let table = CSTTable(
      """
      ^^
      1 ^^
      """
    )

    #expect(table.entries.map(\.value) == ["", ""])
    #expect(table.value(forKey: 1) == "")
  }

  @Test
  func commentLinesAreRemovedFromValues() {
    let table = CSTTable(
      """
      1 ^first
        // A comment.
      # Another.
      /* A block
      comment. */
      last^
      """
    )

    #expect(table.value(forKey: 1) == "first\nlast")
  }

  @Test
  func onlyLineStartsBeginComments() {
    let table = CSTTable(
      """
      1 ^a^ */
      2 ^b // c^
      """
    )

    #expect(table.value(forKey: 1) == "a")
    #expect(table.value(forKey: 2) == "b // c")
  }

  @Test
  func reportsARepeatedKeyAtItsLineInTheFile() {
    let table = CSTTable(
      """
      // A comment.
      2 ^first^

      2 ^second^
      """
    )

    #expect(table.value(forKey: 2) == "first")
    #expect(table.problems == [.repeatedKey("2", line: 4)])
  }

  @Test(arguments: ["next ^separate^", "ok button ^separate^", "  next ^separate^"])
  func unclosedValueStopsAtAWholeEntry(entry: String) {
    let key = entry.prefix { $0 != "^" }.trimmingCharacters(in: .whitespaces)
    let table = CSTTable("broken ^unfinished\nmore\n\(entry)")

    #expect(table.value(forKey: "broken") == nil)
    #expect(table.value(forKey: key) == "separate")
    #expect(table.problems == [.unclosedValue(line: 1)])
    #expect(table.entries.count == 2)
  }

  @Test
  func unclosedValueGivesItsLastLineToTheNextValue() {
    let table = CSTTable(
      """
      broken ^unfinished
      next

      ^separate^
      """
    )

    #expect(table.value(forKey: "next") == "separate")
    #expect(table.entries.map(\.value) == [nil, "separate"])
  }

  @Test
  func unclosedValueAtTheEndOfAFileKeepsItsPlace() {
    let table = CSTTable(
      """
      ^first^
      // A comment.
      ^unfinished
      more
      """
    )

    #expect(table.entries.map(\.value) == ["first", nil])
    #expect(table.problems == [.unclosedValue(line: 3)])
  }

  @Test
  func aValueCanCloseOnALineThatOpensAnother() {
    let table = CSTTable(
      """
      1 ^a
      b^ 2 ^c
      d^
      """
    )

    #expect(table.value(forKey: 1) == "a\nb")
    #expect(table.value(forKey: 2) == "c\nd")
    #expect(table.problems.isEmpty)
  }

  @Test
  func firstValueWinsForARepeatedKey() {
    let table = CSTTable(
      entries: [
        Entry(key: "2", name: nil, value: "first"),
        Entry(key: "2", name: nil, value: "second"),
      ],
      problems: [.repeatedKey("2", line: 2)]
    )

    #expect(table.value(forKey: 2) == "first")
  }

  @Test
  func keyWinsOverANameThatComesFirst() {
    let table = CSTTable(
      entries: [
        Entry(key: nil, name: "shared", value: "named"),
        Entry(key: "shared", name: nil, value: "keyed"),
      ],
      problems: []
    )

    #expect(table.value(forKey: "shared") == "keyed")
  }

  @Test
  func unclosedValueDoesNotHideALaterValue() {
    let table = CSTTable(
      entries: [
        Entry(key: "broken", name: nil, value: nil),
        Entry(key: "broken", name: nil, value: "closed"),
      ],
      problems: [.unclosedValue(line: 1)]
    )

    #expect(table.entries.count == 2)
    #expect(table.value(forKey: "broken") == "closed")
  }

  @Test
  func missingKeyHasNoValue() {
    let table = CSTTable(entries: [Entry(key: "1", name: nil, value: "one")], problems: [])

    #expect(table.value(forKey: "2") == nil)
  }
}
