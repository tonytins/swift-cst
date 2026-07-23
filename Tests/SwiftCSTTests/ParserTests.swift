@testable import SwiftCST
import Testing

@Test func singleLine() {
    
    let expected = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Proin ac dictum orci, at tincidunt nulla. Donec aliquet, eros non interdum posuere, ipsum sapien molestie nunc, nec facilisis libero ipsum et risus. In sed lorem vel ipsum placerat viverra."
    let content = "101 ^\(expected)^"
    let cst = CST.parse(content, key: 101)
    
    #expect(cst == expected)
}

@Test func variableTest() {
    let quickFox = "1 ^The quick brown fox %s over the lazy dog.^"
    let parsed = CST.parse(quickFox, key: 1, variables: "leaps")
    
    #expect(parsed == "The quick brown fox leaps over the lazy dog.")
}

@Test func emojiTest() {
    
    let expected = "We're home!"
    let cst = "🏠 ^\(expected)^"
    let home = CST.parse(cst, key: "🏠")
    
    #expect(home == expected)
}

@Test func multiLine() {
    let input = """
    🦊 ^The quick brown fox %s over the lazy dog.^
    newMail ^You have %d new messages.^
    """

    let quickFox = CST.parse(input, key: "🦊", variables: "leaps")
    let mail = CST.parse(input, key: "newMail", variables: 5)
    
    #expect(quickFox == "The quick brown fox leaps over the lazy dog.")
    #expect(mail == "You have 5 new messages.")
}
