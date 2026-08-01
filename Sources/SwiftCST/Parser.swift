import Foundation

let missingMessage = "*** MISSING ***"

internal let caret: Character = "^"
internal let lineEndings = ["\u{000A}", "\u{000D}",
                                  "\u{000D}\u{000A}", "\u{2028}"]

internal enum PlaceholderKind: Equatable, Codable {
    case string
    case digit
    case paddingDigit(width: Int)
}

enum TemplateNode: Equatable, Codable {
        case literal(String)
        case placeholder(kind: PlaceholderKind, raw: String)
}

internal struct Placeholder {
    let kind: PlaceholderKind
    let range: Range<String.Index>
}

struct CSTEntry: Codable, Equatable {
    let key: String
    let template: String
}

struct TemplateAST {
    let nodes: [TemplateNode]
}

struct CST {
    
    static func parse(_ content: String,
                      key: some CustomStringConvertible,
                      variables: any CustomStringConvertible...) async -> String
    {
        return ""
    }
    
    static func parse(_ content: String,
                      key: some CustomStringConvertible,
                      variables: any CustomStringConvertible...) -> String
    {
        return ""
    }
    
    /* static func parse(_ content: String,
                      key: some CustomStringConvertible,
                      variables: any CustomStringConvertible...) async -> String
    {
        return stringBuilder(content, key: key, variables: variables)
    }

    static func parse(_ content: String,
                      key: some CustomStringConvertible,
                      variables: any CustomStringConvertible...) -> String
    {
        return stringBuilder(content, key: key, variables: variables)
    } */
    
    internal static func stringBuilder(from entries: [CSTEntry],
                                key: some CustomStringConvertible,
                                variables: any CustomStringConvertible...) -> String
    {
        let template = entries.template(
            forKey: String(describing: key)
        ) ?? missingMessage
        let stringVariables = variables.map { String(describing: $0) }
        
        return ""
    }
    
    func entries(fromLines lines: [String]) -> [CSTEntry] {
        var result: [CSTEntry] = []
        
        for index in lines.indices {
           // guard let template = template
        }
        
        return result
    }
    
    static func template(atOrAfter index: Int, in lines: [String]) -> String? {
        if let template = quotedTemplate(in: lines[index]) {
            return template
        }
        
        guard let nextLine = lines[safe: index + 1] else {
            return nil
        }
        
        return quotedTemplate(in: nextLine)
    }
    
    static func quotedTemplate(in line: String) -> String? {
        guard let opening = line.firstIndex(of: caret) else {
            return nil
        }
        let remainder = line[line.index(after: opening)...]
        guard let closing = remainder.firstIndex(of: caret) else { return nil
        }
        
        return String(remainder[..<closing])
    }
    
    static func keyText(of line: String) -> String {
        guard let caretIndex = line.firstIndex(of: caret) else {
            return line.trimmingCharacters(in: .whitespaces)
        }
        
        return String(line[..<caretIndex]).trimmingCharacters(in: .whitespaces)
    }
    
    static func entries(fromJOSN json: Data) throws -> [CSTEntry] {
        try JSONDecoder().decode([CSTEntry].self, from: json)
    }
    
}


extension Array where Element == CSTEntry {
    func template(forKey key: String) -> String? {
        first(where: { $0.key.hasPrefix(key)})?.template
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
