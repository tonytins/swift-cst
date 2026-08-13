import Foundation

@available(macOS 13, *)
struct RegexInterpolating: VariableInterpolating {
    private let placeholderPattern = try! Regex("%(?:(\\d+))?d|%s")
    private let paddingPattern = try! Regex("%(\\d+)d")
    
    func substitute(_ template: String, with variables: [String]) -> String {
        var result = template
        var variableIndex = 0
        
        while variableIndex < variables.count {
            guard let match = result.firstMatch(of: paddingPattern) else {
                break
            }
            
            let matchedText = String(result[match.range])
            let width = paddingWidth(in: matchedText)
            let variableSubstitution = variables[variableIndex].padded(
                toWidth: width
            )
            
            result.replaceSubrange(match.range, with: variableSubstitution)
            variableIndex += 1
        }
        
        return result
    }
    
    func paddingWidth(in matchedText: String) -> Int {
        guard let match = matchedText.firstMatch(
            of: paddingPattern
        ), let digits = match.output[1].substring
        else {return  0 }
        
        
        return Int(digits) ?? 0
    }
}
