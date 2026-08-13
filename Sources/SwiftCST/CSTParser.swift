import Foundation

let missingMessage = "*** MISSING ***"

enum CST {
    private static let caret: Character = "^"
    private static let lineEndings = ["\u{000A}", "\u{000D}",
                                      "\u{000D}\u{000A}", "\u{2028}"]
    
    static var substitutor: VariableSubstituting {
        if #available(macOS 13, *) {
            RegexParser()
        } else {
            LegacyParser()
        }
    }
     
    static func parse(_ content: String,
                      key: some CustomStringConvertible,
                      variables: any CustomStringConvertible...) async -> String
    {
        return scanAndBuild(content, key: key, variables: variables)
    }
    
    static func parse(_ content: String,
                      key: some CustomStringConvertible,
                      variables: any CustomStringConvertible...) -> String
    {
        return scanAndBuild(content, key: key, variables: variables)
    }
    
    private static func scanAndBuild(_ content: String,
                                     key: some CustomStringConvertible,
                                     variables: any CustomStringConvertible...) -> String
    {
        let entries = normalizeEntries(content)
        let entry = findEntry(entries, key: String(describing: key))
        let stringVariables = variables.map { String(describing: $0) }
        
        return substitutor.substitute(entry, with: stringVariables)
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

    private static func findEntry(_ entries: [String], key: String) -> String {
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
    
}
