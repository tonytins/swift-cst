import Foundation

internal let missingMessage = "*** MISSING ***"

struct CST {
    private static let caret: Character = "^"
    private static let lineEndings = ["\u{000A}", "\u{000D}", "\u{000D}\u{000A}", "\u{2028}"]


    static func parse(_ content: String,
                      key: some CustomStringConvertible,
                      variables: any CustomStringConvertible...) -> String {
        
        let entries = normalizeEntries(content)
        let entry = getEntry(entries, key: String(describing: key))
        let convertAnyToString = variables.map { String(describing: $0) }
        
        return substituteVariables(entry, with: convertAnyToString)
    }


    private static func normalizeEntries(_ content: String) -> [String] {
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

    private static func getEntry(_ entries: [String], key: String) -> String {
        for entry in entries {
            guard entry.hasPrefix(key) else { continue }
            guard let startIndex = entry.firstIndex(of: caret) else { continue }

            let line = String(entry[startIndex...])
            return line.trimmingCharacters(
                in: CharacterSet(charactersIn: String(caret)),
            )
        }

        return missingMessage
    }

    private static func substituteVariables(_ template: String, with variables: [String]) -> String {
        var result = template
        var variableIndex = 0
        
        let regex = try! Regex("%(?:(\\d+))?d|%s")
        
        while variableIndex < variables.count {
            guard let match = result.firstMatch(of: regex) else {
                break
            }
            
            let matchedText = String(result[match.range])
            let paddingWidth = extractPaddingWidth(
                from: matchedText
            )
            let substitution = formatVariable(
                variables[variableIndex],
                with: paddingWidth
            )
            
            result.replaceSubrange(match.range, with: substitution)
            variableIndex += 1
        }

        return result
    }
    
    // Boilerplate
    
    private static func extractPaddingWidth(from matchedText: String) -> Int {
        guard matchedText.contains("d") else { return 0 }
        
        let paddingRegex = try! Regex("%(\\d+)d")
        guard let match = matchedText.firstMatch(of: paddingRegex) else { return 0 }
        
        return Int(match.count)
    }
    
    private static func formatVariable(_ value: String, with paddingWidth: Int) -> String {
        guard paddingWidth > 0 else { return value }
        
        return padString(value, toWidth: paddingWidth)
    }
    
    internal static func padString(_ value: String, toWidth width: Int) -> String {
        guard width > 0 else { return value }
        guard value.count < width else { return value }
        
        return String(repeating: "0", count: width - value.count) + value
    }
}
