import Foundation

struct Ledger {
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
    
    private func taggedValue(in line: String) -> String? {
        guard let start = line.firstIndex(of: Self.caret) else {
            return nil
        }
        
        let tagged = line[start...]
        
        guard tagged.count > 1, tagged.hasPrefix(String(Self.caret)) else {
            return nil
        }
        
        return String(tagged.dropFirst().dropLast())
    }
    
    func entries(forKey key: String) -> String {
        for (index, line) in lines.enumerated() where line.hasPrefix(key) {
            if line == key {
                guard index + 1 < lines.count, let value = taggedValue(in: lines[index + 1]) else {
                    continue
                }
                return value
            }
            
            if let value = taggedValue(in: line) {
                return value
            }
        }
        
        return missingMessage
    }
    
}
