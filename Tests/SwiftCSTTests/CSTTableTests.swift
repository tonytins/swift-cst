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
      Entry(key: "9", name: "A label", value: "A numbered key above its value"),
      Entry(key: "10", name: nil, value: "A numbered key on its line"),
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
  func readsSeveralValuesOnOneLine() {
    let table = CSTTable("7 ^One^ 8 ^Two^ ^Third^")

    #expect(table.value(forKey: 7) == "One")
    #expect(table.value(forKey: 8) == "Two")
    #expect(table.entries.map(\.key) == ["7", "8", nil])
    #expect(table.entries[2].value == "Third")
  }

  @Test
  func aKeyNeedsNoSpaceBeforeItsValue() {
    #expect(CSTTable("6^No space^").value(forKey: 6) == "No space")
  }

  @Test
  func aClosingCaretCanSitOnItsOwnLine() {
    let table = CSTTable(
      """
      1 ^First line
      last ^
      2 ^Next^
      3 ^One
      ^
      4 ^After^
      """
    )

    #expect(table.value(forKey: 1) == "First line\nlast ")
    #expect(table.value(forKey: 2) == "Next")
    #expect(table.value(forKey: 3) == "One\n")
    #expect(table.value(forKey: 4) == "After")
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

  @Test
  func numberedKeysKeepTheirLabelAsAName() {
    let table = CSTTable(
      """
      1.new house window name
      \t^New World^

      5.
      \t^:not used^

      19. lights directory
      \t^Lights^
      1:^biped^
      """
    )

    #expect(
      table.entries == [
        Entry(key: "1", name: "new house window name", value: "New World"),
        Entry(key: "5", name: nil, value: ":not used"),
        Entry(key: "19", name: "lights directory", value: "Lights"),
        Entry(key: "1", name: nil, value: "biped"),
      ]
    )
    #expect(table.value(forKey: 1) == "New World")
    #expect(table.value(forKey: "lights directory") == "Lights")
    #expect(table.problems == [.repeatedKey("1", line: 9)])
  }

  @Test(arguments: ["1.5", "10:30", "1.5 kg", "v1.2", "1 . 2"])
  func numbersThatAreNotNumberedKeysStayWhole(text: String) {
    let above = CSTTable("\(text)\n^above^")
    let before = CSTTable("\(text) ^before^")

    #expect(above.value(forKey: text) == "above")
    #expect(before.value(forKey: text) == "before")
  }

  /// Reads every table of a local Sims Steering Committee install, when `SSC_GAME_DIR` is set.
  ///
  /// SSC keeps its tables in `.dir` folders beside its `.iff` files, named `#<id>#<name>.cst`.
  @Test
  func readsEveryTableOfALocalSteeringCommitteeInstall() throws {
    guard let install = ProcessInfo.processInfo.environment["SSC_GAME_DIR"] else {
      return
    }

    let enumerator = try #require(
      FileManager.default.enumerator(
        at: URL(fileURLWithPath: install), includingPropertiesForKeys: nil)
    )
    let files = enumerator.compactMap { $0 as? URL }.filter {
      $0.pathExtension.lowercased() == "cst"
    }

    #expect(!files.isEmpty)

    for file in files {
      let table = CSTTable(try String(contentsOf: file, encoding: .utf8))

      #expect(table.problems.isEmpty, "\(file.lastPathComponent)")
      #expect(table.entries.allSatisfy { $0.value != nil }, "\(file.lastPathComponent)")
    }
  }
}
