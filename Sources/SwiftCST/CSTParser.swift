import Foundation

let missingMessage = "*** MISSING ***"

enum CST {
    private static let caret: Character = "^"
    private static let lineEndings = ["\u{000A}", "\u{000D}",
                                      "\u{000D}\u{000A}", "\u{2028}"]

    static func parse(_ content: String,
                      key: some CustomStringConvertible,
                      variables: any CustomStringConvertible...) -> String
    {
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

    private static func substituteVariables(_ template: String,
                                            with variables: [String]) -> String
    {
        var result = template
        var variableIndex = 0

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
    private static func performPaddedSubstitution(from matchedText: String) -> Int {
        guard matchedText.contains("d") else { return 0 }

        let paddingRegex = try! Regex("%(\\d+)d")
        guard let match = matchedText.firstMatch(of: paddingRegex) else { return 0 }

        return Int(match.count)
    }

    private static func performPaddedSubstitution(_ result: inout String,
                                                  formatRange _: Range<String.Index>, nextIndex: String.Index,
                                                  variables _: [String],
                                                  variableIndex _: inout Int,
                                                  searchStartIndex: inout String.Index)
    {
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
        // let paddedValue = padString(variables[variableIndex], toWidth: padCount)
        let finalEndIndex = result.index(after: endIndex)
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
