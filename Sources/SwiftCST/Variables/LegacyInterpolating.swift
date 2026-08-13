import Foundation

struct LegacyInterpolating: VariableInterpolating {
    func substitute(_ template: String, with variables: [String]) -> String {
        var result = template
        var variableIndex = 0
        var searchStartIndex = result.startIndex
        
        while variableIndex < variables.count, searchStartIndex < result.endIndex {
            guard let percentRange = result.range(of: "%", range: searchStartIndex..<result.endIndex) else {
                break
            }
            
            let formatIndex = result.index(after: percentRange.lowerBound)
            let formatChar = result[formatIndex]
            
            
            switch formatChar {
            case "d", "s":
                let placeholderEnd = result.index(after: formatIndex)
                let substitution = variables[variableIndex]
                
                result.replaceSubrange(percentRange.lowerBound ..< placeholderEnd, with: substitution)
                searchStartIndex = result.index(percentRange.lowerBound, offsetBy: substitution.count)
                variableIndex += 1
            case _ where formatChar.isNumber:
                replacePaddedPlaceholder(in: &result,
                                         percentRange: percentRange,
                                         digitsStart: formatIndex,
                                         variables: variables,
                                         variableIndex: &variableIndex,
                                         searchStartIndex: &searchStartIndex)
            default:
                searchStartIndex = result.index(after: formatIndex)
            }
        }
        
  
        
        return result
    }
    
    
    private func replacePaddedPlaceholder(in result: inout String,
                                          percentRange: Range<String.Index>,
                                          digitsStart: String.Index,
                                          variables: [String],
                                          variableIndex: inout Int,
                                          searchStartIndex: inout String.Index)
    {
        var digitsEnd = digitsStart
        var widthDigits = ""
        
        while digitsEnd < result.endIndex, result[digitsEnd].isNumber {
            widthDigits.append(result[digitsEnd])
            digitsEnd = result.index(after: digitsEnd)
        }
        
        guard digitsEnd < result.endIndex, result[digitsEnd] == "d" else {
            searchStartIndex = result.index(after: digitsStart)
            return
        }
        
        let width = Int(widthDigits) ?? 0
        let substitution = variables[variableIndex].padded(toWidth: width)
        let placeholderEnd = result.index(after: digitsEnd)
        
        result.replaceSubrange(percentRange.lowerBound ..< placeholderEnd, with: substitution)
        variableIndex += 1
        searchStartIndex = result.index(percentRange.lowerBound, offsetBy: substitution.count)
        
    }
    
}
