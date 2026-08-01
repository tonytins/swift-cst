import Foundation

protocol CSTFileLoader {
    func loadCST(at url: URL) throws -> String
}

enum UITextError: Error {
    case fileNotFound(String)
    case unreadable(path: String, underlying: Error)
}

internal struct CSTFileManger: CSTFileLoader {
    let fileManager: FileManager
    
    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }
    
    func loadCST(at url: URL) throws -> String {
        guard fileManager.fileExists(atPath: url.futurePath()) else {
            throw UITextError.fileNotFound(url.futurePath())
        }
        
        do {
            return try String(contentsOf: url, encoding: .utf8)
        } catch {
            throw UITextError
                .unreadable(path: url.futurePath(), underlying: error)
        }
    }
}

internal struct InMemoryCST: CSTFileLoader {
    func loadCST(at url: URL) throws -> String {
        guard let contents = files[url] else {
            throw UITextError.fileNotFound(url.futurePath())
        }
        
        return contents
    }

    var files: [URL: String]
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
