import Foundation

// TODO: Remove "internal" keywords when UIText has been fully tested
internal struct UIText {

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
    
    func getText(id: some CustomStringConvertible,
                 key: some CustomStringConvertible, variables: any CustomStringConvertible...) -> String {
        let langPath = languageDictionaryPath(for: language)
        guard fileSystemAvailable(at: langPath) else { return missingMessage }
        
        guard let filePath = readFileContent(at: langPath) else {
            return missingMessage
        }
        
        guard let content = readFileContent(at: filePath) else {
            return missingMessage
        }
        
        return CST.parse(content, key: key, variables: variables)
    }
    
    private func findLanguageFile(in directory: String, with id: Int) -> String? {
        let fileManager = FileManager.default
        guard let files = try? fileManager.contentsOfDirectory(
            atPath: directory
        ) else { return nil }
        
        let filePattern = "_\(id)_"
        let cstFile = files.first { file in
            file.contains(filePattern) && file.hasSuffix(".cst")
        }
        
        guard let fileName = cstFile else { return nil }
        
        return (directory as NSString).appendingPathComponent(fileName)
        
    }
    
    private func readFileContent(at path: String) -> String? {
        do {
            return try String(contentsOfFile: path, encoding: .utf8)
        } catch {
            return nil
        }
    }
    
    private func languageDictionaryPath(for language: String) -> String {
        let languageDir = "\(language).dir"
        return (basePath as NSString).appendingPathComponent(languageDir)
    }
    
    private static func defaultBasePath() -> String {
        let bundlePath = Bundle.main.bundlePath
        return (bundlePath as NSString).appendingPathComponent("uitext")
    }
    
    private func fileSystemAvailable(at path: String) -> Bool {
        FileManager.default.fileExists(atPath: path)
    }
}
