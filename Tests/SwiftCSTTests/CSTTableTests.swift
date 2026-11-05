import Testing

@testable import SwiftCST

struct CSTTableTests {
  private typealias Entry = CSTTable.Entry

  @Test
  func readsSpecificationExample() {
    let document = """
      // A comment. So is a line starting with #, and a /* */ block.
      1 ^A value after its key^
          2 ^An indented key^
      3
      ^A key above its value^
      4 ^A value that runs
      across lines^
      ok button ^A key with spaces^
      kErrNoFood
      ^A name above its value^
      A note for translators.

      ^A value with a note above it^
      ^A value on its own^ with a note after it
      ^Another value on its own^
      """

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

    withKnownIssue("CSTTable doesn't scan documents yet") {
      let table = CSTTable(document)

      #expect(table.entries == expected)
      #expect(table.problems.isEmpty)
    }
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
