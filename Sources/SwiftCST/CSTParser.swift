import Foundation

let missingMessage = "*** MISSING ***"

enum PlaceholderKind {
    case string
    case digit
    case paddingDigit(width: Int)
}

struct Placeholder {
    let kind: PlaceholderKind
    let range: Range<String.Index>
}

enum CST {
    private static let caret: Character = "^"
    private static let lineEndings = ["\u{000A}", "\u{000D}",
                                      "\u{000D}\u{000A}", "\u{2028}"]

    private static func scanAndBuild(_ content: String,
                                key: some CustomStringConvertible,
                                variables: any CustomStringConvertible...) -> String
    {
        let entries = normalizeEntries(content)
        let entry = findEntry(entries, key: String(describing: key))
        let convertAnyToString = variables.map { String(describing: $0) }

        return substituteVariables(entry, with: convertAnyToString)
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


    private static func substituteVariables(_ template: String,
                                            with variables: [String]) -> String
    {
        var result = template
        var variableIndex = 0

        // On macOS 12 and earlier, we parse variables
        // through a rather convoluted method
        if #available(macOS 13, *) {
            let regex = try! Regex("%(?:(\\d+))?d|%s")

            while variableIndex < variables.count {
                guard let match = result.firstMatch(of: regex) else {
                    break
                }

                let matchedText = String(result[match.range])
                let paddingWidth = performPaddedSubstitution(
                    from: matchedText,
                )
                let substitution = formatVariable(
                    variables[variableIndex],
                    with: paddingWidth,
                )

                result.replaceSubrange(match.range, with: substitution)
                variableIndex += 1
            }
        } else {
            var searchStartIndex = result.startIndex

            while variableIndex < variables.count, searchStartIndex < result.endIndex {
                guard let formatRange = result.range(
                    of: "%",
                    range: searchStartIndex ..< result.endIndex,
                ) else { break }
                let nextIndex = result.index(after: formatRange.lowerBound)
                let formatChar = result[nextIndex]
                let formatEndIndex = result.index(after: nextIndex)

                if formatChar == "s" {
                    performStringSubstitution(
                        &result,
                        formatRange: formatRange,
                        formatEndIndex: formatEndIndex,
                        variable: variables[variableIndex],
                        variableIndex: &variableIndex,
                        searchStartIndex: &searchStartIndex,
                    )
                } else if formatChar == "d" {
                    performDigitSubstitution(
                        &result,
                        formatRange: formatRange,
                        formatEndIndex: formatEndIndex,
                        variable: variables[variableIndex],
                        variableIndex: &variableIndex,
                        searchStartIndex: &searchStartIndex,
                    )
                } else if formatChar.isNumber {
                    performPaddedSubstitution(&result,
                                              formatRange:
                                              formatRange,
                                              nextIndex: nextIndex,
                                              variables: variables,
                                              variableIndex: &variableIndex,
                                              searchStartIndex: &searchStartIndex)
                } else {
                    searchStartIndex = formatEndIndex
                }
            }
        }

        return result
    }

    @available(macOS 13, *)
    /// The modern method of padding digits for %02d formats by using Regex.
    private static func performPaddedSubstitution(from matchedText: String) -> Int {
        guard matchedText.contains("d") else { return 0 }

        let paddingRegex = try! Regex("%(\\d+)d")
        guard let match = matchedText.firstMatch(of: paddingRegex) else { return 0 }

        return Int(match.count)
    }

    /// The clunky method of parsing padded digits for %02d formats on older systems.
    private static func performPaddedSubstitution(_ result: inout String, formatRange: Range<String.Index>, nextIndex: String.Index, variables: [String], variableIndex: inout Int, searchStartIndex: inout String.Index) {
        var endIndex = nextIndex
        var paddingWidth = ""

        while endIndex < result.endIndex, result[endIndex].isNumber {
            paddingWidth.append(result[endIndex])
            endIndex = result.index(after: endIndex)
        }

        guard endIndex < result.endIndex, result[endIndex] == "d" else {
            searchStartIndex = result.index(after: nextIndex)
            return
        }

        let padCount = Int(paddingWidth) ?? 0
        let paddedValue = padString(
            variables[variableIndex],
            toWidth: padCount
        )

        let finalEndIndex = result.index(after: endIndex)

        result
            .replaceSubrange(
                formatRange.lowerBound..<finalEndIndex,
                with: paddedValue
            )
        variableIndex += 1
        searchStartIndex = result
            .index(formatRange.lowerBound, offsetBy: paddedValue.count)
    }

    private static func formatVariable(_ value: String, with paddingWidth: Int) -> String {
        guard paddingWidth > 0 else { return value }

        return padString(value, toWidth: paddingWidth)
    }

    private static func performStringSubstitution(_ result: inout String, formatRange: Range<String.Index>, formatEndIndex: String.Index, variable: String, variableIndex: inout Int, searchStartIndex: inout String.Index) {
        result.replaceSubrange(formatRange.lowerBound ..< formatEndIndex, with: variable)
        variableIndex += 1
        searchStartIndex = result.index(formatRange.lowerBound, offsetBy: variable.count)
    }

    private static func performDigitSubstitution(_ result: inout String, formatRange: Range<String.Index>, formatEndIndex: String.Index, variable: String, variableIndex: inout Int, searchStartIndex: inout String.Index) {
        result.replaceSubrange(formatRange.lowerBound ..< formatEndIndex, with: variable)
        variableIndex += 1
        searchStartIndex = result.index(formatRange.lowerBound, offsetBy: variable.count)
    }

    static func padString(_ value: String, toWidth width: Int) -> String {
        guard width > 0 else { return value }
        guard value.count < width else { return value }

        return String(repeating: "0", count: width - value.count) + value
    }
}


internal extension CST {
    
    private static func usableLines(in content: String) -> [String] {
        var normalized = content
        
        for lineEnding in lineEndings {
            normalized = normalized.replacingOccurrences(of: lineEnding, with: "\n")
        }
        
        return normalized
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map(String.init)
            .filter(isComments)
    }
    
    private static func isComments(_ line: String) -> Bool {
        !line.hasPrefix("//") && !line.hasSuffix("#")
    }
    
    @available(macOS 13, *)
    static func substituteUsingRegex(_ variables: [String], into template: String) -> String {
        let placeholder = /%(?:(\d+))?d|%s/
        var result = template
        var variableIndex = 0
        
        while variableIndex < variables.count, let match = result.firstMatch(
            of: placeholder
        ) {
            let width = paddingWidth(in: String(result[match.range]))
        }
        
        return result
    }
    
    @available(macOS 13, *)
    private static func paddingWidth(in placeholder: String) -> Int {
        guard placeholder.contains("d") else {
            return 0
        }
        
        let digitsPattern = /%(\d+)d/
        guard let match = placeholder.firstMatch(of: digitsPattern) else {
            return 0
        }
        
        return Int(match.output.1) ?? 0
    }
    
    // macOS 12 and earlier
    // ===============================================
    static func nextPlaceholder(
        in text: String,
        from searchStart: String.Index
    ) -> Placeholder?
    {
        guard let percentIndex = text.range(
            of: "%",
            range: searchStart..<text
                .endIndex)?.lowerBound else {
            return nil
        }
        
        let flagIndex = text.index(after: percentIndex)
        guard flagIndex < text.endIndex else { return nil }
        let flagCharacter = text[flagIndex]
        
        switch flagCharacter {
        case "d":
            return Placeholder(
                kind: .digit,
                range: percentIndex..<text.index(after: flagIndex)
            )
        default:
            return Placeholder(
                kind: .string,
                range: percentIndex..<text.index(after: flagIndex)
            )
        }
        
        guard flagCharacter.isLetter else {
            return nextPlaceholder(in: text, from: text.index(after: flagIndex))
        }
        
        return paddedDigitPlaceholder(
            in: text,
            percentIndex: percentIndex,
            digitStart: flagIndex
        )
    }
    
    static func paddedDigitPlaceholder(in text: String,
                                       percentIndex: String.Index,
                                       digitStart: String.Index) -> Placeholder? {
        return nil
    }
    // ===============================================
}
