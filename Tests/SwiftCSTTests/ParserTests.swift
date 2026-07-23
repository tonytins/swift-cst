@testable import SwiftCST
import Testing

// TODO: name these better

let leapingFox: String = "The quick brown fox leaped over the lazy dog."
let quickFox: String = "The quick brown fox %s over the lazy dog."
let foxAction = "leaped"

// WARNING: These will temporarily fail on macOS 12 and earlier!

@Test func singleLine() {
    
    let expected = "The quick brown fox jumps over the lazy dog."
    let content = "1 ^\(expected)^"
    let parsed = CST.parse(content, key: 1)
    
    #expect(parsed == expected)
}

@Test func variableTest() {
    
    let parsed = CST.parse("1 ^\(quickFox)^", key: 1, variables: foxAction)
    
    #expect(parsed == leapingFox)
}

@Test func emojiTest() {
    
    let parsed = CST.parse("🦊 ^\(quickFox)^", key: "🦊", variables: foxAction)
    
    #expect(parsed == leapingFox)
}

@Test func multiLine() {
    let input = """
    🦊 ^\(quickFox)^
    newMail ^You have %d new messages.^
    """

    let fox = CST.parse(input, key: "🦊", variables: foxAction)
    let mail = CST.parse(input, key: "newMail", variables: 5)
    
    #expect(fox == leapingFox)
    #expect(mail == "You have 5 new messages.")
}
