import Testing

@testable import SwiftCST

struct ParserTests {
  let quickFox: String = "The quick brown fox %s over the lazy dog."

  @Test(arguments: ["1", "🦊", "fox"])
  func singleLineTest(key: String) async {
    let parsed = await CST.parse(
      "\(key) ^\(quickFox)^",
      key: key,
      variables: "jumped",
    )

    #expect(parsed == "The quick brown fox jumped over the lazy dog.")
  }

  @Test
  func multilineValuesAndKeysOnSeparateLines() async {
    let input = """
      fox
      ^The quick brown fox %s
      over the lazy dog.^
      mail
      ^You have %02d new messages.^
      """

    let fox = await CST.parse(input, key: "fox", variables: "jumped")
    let mail = await CST.parse(input, key: "mail", variables: 5)

    #expect(fox == "The quick brown fox jumped\nover the lazy dog.")
    #expect(mail == "You have 05 new messages.")
  }

  @Test
  func multilineValueWithKeyOnSameLine() async {
    let input = "fox ^The quick brown fox\njumps over the lazy dog.^"
    let parsed = await CST.parse(input, key: "fox")

    #expect(parsed == "The quick brown fox\njumps over the lazy dog.")
  }

  @Test
  func interpolationPreservesUnmatchedPlaceholders() async {
    let parsed = await CST.parse(
      "mail ^%s %d %03d %1^",
      key: "mail",
      variables: "Messages", 7, 4
    )

    #expect(parsed == "Messages 7 004 %1")
  }

  @Test
  func interpolationPreservesUnknownAndIncompletePlaceholders() async {
    let parsed = await CST.parse("note ^%q %s %^", key: "note")

    #expect(parsed == "%q %s %")
  }

  @Test
  func interpolationDoesNotRescanInsertedVariables() async {
    let parsed = await CST.parse("note ^%s^", key: "note", variables: "%d")

    #expect(parsed == "%d")
  }
}
