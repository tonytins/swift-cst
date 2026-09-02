import Testing

@testable import SwiftCST

struct ParserTests {
  // TODO: name these better
  let quickFox: String = "The quick brown fox %s over the lazy dog."

  func quickFoxAction(do action: String) -> String {
    return "The quick brown fox \(action) over the lazy dog."
  }

  @Test(arguments: ["1", "🦊", "fox"], ["jumped", "leaped", "flew"])
  func singleLineTest(keys: String, action: String) async {
    let parsed = await CST.parse(
      "\(keys) ^\(quickFox)^",
      key: keys,
      variables: action,
    )

    #expect(parsed == quickFoxAction(do: action))
  }

  @Test(
    arguments: ["1", "🦊", "fox"], ["mail", "2", "📧", "📫"]
  )
  func multiLineTest(fox: String, action: String, mail: String) async {
    let input = """
      \(fox) ^\(quickFox)^
      \(mail) ^You have %d new messages.^
      """

    let fox = await CST.parse(input, key: fox, variables: action)
    let mail = await CST.parse(input, key: mail, variables: 5)

    #expect(fox == quickFoxAction(do: action))
    #expect(mail == "You have 5 new messages.")
  }
}
