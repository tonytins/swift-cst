import Foundation

protocol UIText {
    var basePath: String { get set }
    
    func getText(id: Int, key: Int) -> String
    func getText(id: Int, key: String) -> String
}

// TODO: Remove internal keyword when finished
internal struct LocalizedText: UIText {
    private var language: String
    var basePath: String
    
    init() {
        self.language = "english"
        self.basePath = Self.defaultBasePath()
    }
    
    init(language: String) {
        self.language = language
        self.basePath = Self.defaultBasePath()
    }
    
    init(language: String, basePath: String) {
        self.language = language
        self.basePath = basePath
    }
    
    
    func getText(id: Int, key: String) -> String {
        let langPath = languageDictionaryPath(for: language)
        
        
        return ""
        // return CST.parse(, key: <#T##Int#>, variables: <#T##String...##String#>)
    }
    
    func getText(id: Int, key: Int) -> String {
        getText(id: id, key: String(key))
    }
    
    private func languageDictionaryPath(for language: String) -> String {
        let languageDir = "\(language).dir"
        return (basePath as NSString).appendingPathComponent(languageDir)
    }
    
    private static func defaultBasePath() -> String {
        let bundlePath = Bundle.main.bundlePath
        return (bundlePath as NSString).appendingPathComponent("uitext")
    }
}
