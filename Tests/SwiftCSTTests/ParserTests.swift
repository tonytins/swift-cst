import Testing

@testable import SwiftCST

struct ParserTests {
  let quickFox: String = "The quick brown fox %s over the lazy dog."

  @Test(arguments: ["1", "🦊", "fox"])
  func singleLineTest(key: String) {
    let parsed = CST.parse(
      "\(key) ^\(quickFox)^",
      key: key,
      variables: "jumped",
    )

    #expect(parsed == "The quick brown fox jumped over the lazy dog.")
  }

  @Test
  func multilineValuesAndKeysOnSeparateLines() {
    let input = """
      fox
      ^The quick brown fox %s
      over the lazy dog.^
      mail
      ^You have %02d new messages.^
      """

    let fox = CST.parse(input, key: "fox", variables: "jumped")
    let mail = CST.parse(input, key: "mail", variables: 5)

    #expect(fox == "The quick brown fox jumped\nover the lazy dog.")
    #expect(mail == "You have 05 new messages.")
  }

  @Test
  func multilineValueWithKeyOnSameLine() {
    let input = "fox ^The quick brown fox\njumps over the lazy dog.^"
    let parsed = CST.parse(input, key: "fox")

    #expect(parsed == "The quick brown fox\njumps over the lazy dog.")
  }

  @Test
  func ignoresLineAndBlockComments() {
    let input = """
      // whole-line comment
      # another supported comment
      /*
      ignored ^block contents^
      */
      message ^visible^
      """
    let parsed = CST.parse(input, key: "message")

    #expect(parsed == "visible")
  }

  @Test
  func ignoresCommentLinesInsideMultilineValues() {
    let input = """
      message ^first line
      // ignored line
      second line^
      """
    let parsed = CST.parse(input, key: "message")

    #expect(parsed == "first line\nsecond line")
  }

  @Test
  func unterminatedValueDoesNotConsumeFollowingEntry() {
    let sameLineEntry = """
      broken ^unfinished value
      next ^separate value^
      """
    let separateLineEntry = """
      broken ^unfinished value
      next
      ^separate value^
      """

    #expect(CST.parse(sameLineEntry, key: "broken") == "*** MISSING ***")
    #expect(CST.parse(sameLineEntry, key: "next") == "separate value")
    #expect(CST.parse(separateLineEntry, key: "broken") == "*** MISSING ***")
    #expect(CST.parse(separateLineEntry, key: "next") == "separate value")
  }

  @Test
  func keyMustEndAtAKeyBoundary() {
    let input = """
      foxes ^not the requested entry^
      fox ^the requested entry^
      """

    #expect(CST.parse(input, key: "fox") == "the requested entry")
  }

  @Test
  func interpolationPreservesUnmatchedPlaceholders() {
    let parsed = CST.parse(
      "mail ^%s %d %03d %1^",
      key: "mail",
      variables: "Messages", 7, 4
    )

    #expect(parsed == "Messages 7 004 %1")
  }

  @Test
  func interpolationPreservesUnknownAndIncompletePlaceholders() {
    let parsed = CST.parse("note ^%q %s %^", key: "note")

    #expect(parsed == "%q %s %")
  }

  @Test
  func interpolationDoesNotRescanInsertedVariables() {
    let parsed = CST.parse("note ^%s^", key: "note", variables: "%d")

    #expect(parsed == "%d")
  }

  @Test
  func asyncParserCompatibilityOverload() async {
    let parsed = await CST.parse("hello ^Hello!^", key: "hello")

    #expect(parsed == "Hello!")
  }
}
