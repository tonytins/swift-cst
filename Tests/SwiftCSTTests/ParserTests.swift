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

  @Test(arguments: ["ok", "24", ""])
  func keyMustMatchWhole(key: String) {
    let input = """
      ok button ^button^
      24 012 ^reason^
      ^keyless^
      """

    #expect(CST.parse(input, key: key) == "*** MISSING ***")
  }

  @Test
  func unclosedValueDoesNotConsumeAKeyWithSpaces() {
    let input = """
      1 ^unclosed
      ok button ^button^
      """

    #expect(CST.parse(input, key: 1) == "*** MISSING ***")
    #expect(CST.parse(input, key: "ok button") == "button")
  }

  @Test(arguments: ["%s", "%d", "%i", "%u", "%ld", "%li", "%lu"])
  func placeholdersTakeAVariable(placeholder: String) {
    #expect(CST.parse("1 ^[\(placeholder)]^", key: 1, variables: 7) == "[7]")
  }

  @Test(
    arguments: zip(
      ["%03d", "%3d", "%.2d", "%03i", "%.2u", "%02ld"],
      ["007", "007", "07", "007", "07", "07"]
    ))
  func numberPlaceholdersPadWithZeros(placeholder: String, expected: String) {
    #expect(CST.parse("1 ^\(placeholder)^", key: 1, variables: 7) == expected)
  }

  @Test
  func doubledPercentBecomesOnePercentWithoutUsingAVariable() {
    #expect(CST.parse("1 ^%%d %d%%^", key: 1, variables: 7) == "%d 7%")
    #expect(CST.parse("1 ^100%%^", key: 1) == "100%")
  }

  @Test(arguments: ["%.d", "%ls", "%l", "%.", "%5", "to sell % for $", "<%>", "%x"])
  func otherUsesOfPercentStayAsWritten(text: String) {
    #expect(CST.parse("1 ^\(text)^", key: 1, variables: 7) == text)
  }

  @Test
  func asyncParserCompatibilityOverload() async {
    let parsed = await CST.parse("hello ^Hello!^", key: "hello")

    #expect(parsed == "Hello!")
  }
}
