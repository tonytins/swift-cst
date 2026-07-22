@testable import SwiftCST
import Testing

@Test func singleLine() {
    let content = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Proin ac dictum orci, at tincidunt nulla. Donec aliquet, eros non interdum posuere, ipsum sapien molestie nunc, nec facilisis libero ipsum et risus. In sed lorem vel ipsum placerat viverra."
    let cst = "101 ^\(content)^"
    
    let lorem = CST.parse(cst, key: 101)
    
    #expect(lorem == content)
}

@Test func variableTest() {
    let cst = "1 ^Hello %s!^"
    
    let helloWorld = CST.parse(cst, key: 1, variables: "World")
    
    #expect(helloWorld == "Hello World!")
}
