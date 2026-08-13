import Foundation

struct LegacyParser: VariableSubstituting {
    func substitute(_ template: String, with variables: [String]) -> String {
        var result = template
        
        return result
    }
    
    // Just dumping this here for now
    private static func substituteVariables(_ template: String,
                                            with variables: [String]) -> String
    {
        var result = template
        var variableIndex = 0
        
        // On macOS 12 and earlier, we parse variables
        // through a rather convoluted method.
        if #available(macOS 13, *) {
            let regex = try! Regex("%(?:(\\d+))?d|%s")
            
            while variableIndex < variables.count {
                guard let match = result.firstMatch(of: regex) else {
                    break
                }
                
                /* let matchedText = String(result[match.range])
                let paddingWidth = performPaddedSubstitution(
                    from: matchedText,
                )
                let substitution = formatVariable(
                    variables[variableIndex],
                    with: paddingWidth,
                )
                
                result.replaceSubrange(match.range, with: substitution) */
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
        
        /* let padCount = Int(paddingWidth) ?? 0
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
            .index(formatRange.lowerBound, offsetBy: paddedValue.count) */
    }
    
    private static func formatVariable(_ value: String, with paddingWidth: Int) -> String {
        guard paddingWidth > 0 else { return value }
        
        return ""
        // return padString(value, toWidth: paddingWidth)
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
}
