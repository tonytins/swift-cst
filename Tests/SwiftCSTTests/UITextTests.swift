import Foundation
@testable import SwiftCST
import Testing

@Suite("UIText")
struct UITextTests {
    
    func fixedURL(language: String = "english", id: String = "greetings") -> URL
    {
        let url = URL(fileURLWithPath: ".")
        if #available(macOS 13.0, *) {
            return url.appending(path: "translations")
                .appending(path: "\(language).cst")
                .appending(path: "\(id).cst")
        } else {
            return url.appendingPathComponent("translations")
                .appendingPathComponent("\(language).cst")
                .appendingPathComponent("\(id).cst")
        }
    }
    
    @Test func loadAndParse() async throws {
        let url = fixedURL()
        let loader = InMemoryCST(files: [url: "1 ^Hello %s!^"])
        let text = UIText(loader: loader)
        
        let result = try await text.getText(file: "greetings", key: 1, variables: "World")
        #expect(result == "Hello World!")
    }
}
