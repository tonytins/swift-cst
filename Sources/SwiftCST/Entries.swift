import Foundation

struct Entries {
    private static let caret: Character = "^"
    private static let lineEndings = ["\u{000A}", "\u{000D}",
                                      "\u{000D}\u{000A}", "\u{2028}"]
    
    let lines: [String]
    
    init(content: String) {
        self.lines = Self.normalize(content)
    }
    
    private static func normalize(_ content: String) -> [String] {
        var normalized = content
        
        for lineEnding in lineEndings {
            normalized = normalized.replacingOccurrences(of: lineEnding, with: "\n")
        }
        
        return normalized
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { String($0) }
            .filter {
                line in
                !line.hasPrefix("//") && !line.hasSuffix("#")
                && !line.hasPrefix("/*") && !line.hasSuffix("*/")
            }
    }
    
}
