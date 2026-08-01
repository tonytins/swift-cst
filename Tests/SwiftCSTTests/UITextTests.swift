import Foundation
@testable import SwiftCST
import Testing

@Suite("UIText")
struct UITextTests {
    
    func mockedPath(language: String = "english", file: String = "greetings") -> URL
    {
        let url = URL(fileURLWithPath: ".")
        if #available(macOS 13.0, *) {
            return url.appending(path: "uitext")
                .appending(path: "\(language).cst")
                .appending(path: "\(file).cst")
        } else {
            return url.appendingPathComponent("uitext")
                .appendingPathComponent("\(language).cst")
                .appendingPathComponent("\(file).cst")
        }
    }
    
    @Test func loadAndParse() async throws {
        let url = mockedPath()
        let loader = InMemoryCST(files: [url: "1 ^Hello %s!^"])
        let text = UIText(loader: loader)
        
        let result = try await text.getText(file: "greetings", key: 1, variables: "World")
        #expect(result == "Hello World!")
    }
}
