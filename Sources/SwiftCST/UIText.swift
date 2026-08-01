import Foundation


enum UITextError: Error {
    case fileNotFound(String)
    case unreadable(path: String, underlying: Error)
}

struct UIText {
    let language: String
    let basePath: String
    let loader: CSTFileLoader
    
    init(language: String = "english",
         basePath: String = ".",
         loader: CSTFileLoader = CSTFileManger()) {
        self.language = language
        self.basePath = basePath
        self.loader = loader
    }

    func getText(file: String,
                 key: some CustomStringConvertible,
                 variables: any CustomStringConvertible...) async throws -> String
    {
        let content = try loader.loadCST(at: fileURL(forFile: file))
        return CST.scanAndBuild(content, key: key, variables: variables)
    }
    
    func fileURL(forFile file: String) -> URL {
        let url = URL(fileURLWithPath: basePath)
        if #available(macOS 13.0, *) {
            return url.appending(path: "translations")
                .appending(path: "\(language).cst")
                .appending(path: "\(file).cst")
        } else {
            return url.appendingPathComponent("translations")
                .appendingPathComponent("\(language).cst")
                .appendingPathComponent("\(file).cst")
        }
    }

}
