@testable import SwiftCST
import Testing

@Test func singleLine() {
    
    let expected = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Proin ac dictum orci, at tincidunt nulla. Donec aliquet, eros non interdum posuere, ipsum sapien molestie nunc, nec facilisis libero ipsum et risus. In sed lorem vel ipsum placerat viverra."
    let content = "101 ^\(expected)^"
    let cst = CST.parse(content, key: 101)
    
    #expect(cst == expected)
}

@Test func variableTest() {
    
    let content = "1 ^Hello %s!^"
    let cst = CST.parse(content, key: 1, variables: "World")
    
    #expect(cst == "Hello World!")
}

@Test func emojiTest() {
    
    let expected = "We're home!"
    let cst = "🏠 ^\(expected)^"
    let home = CST.parse(cst, key: "🏠")
    
    #expect(home == expected)
}
