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
        let ledger = Ledger(content: content)
        let entry = ledger.entries(forKey: String(describing: key))
        let stringVariables = variables.map { String(describing: $0) }
        
        return substitutor.substitute(entry, with: stringVariables)
    }
}
