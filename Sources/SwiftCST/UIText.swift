import Foundation
import FutureFoundations

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

    func getText(id: String,
                 key: some CustomStringConvertible,
                 variables: any CustomStringConvertible...) async throws -> String
    {
        let content = try loader.loadCST(
            at: resolvedFileURL(forID: id))
        
        return await CST.parse(content, key: key, variables: variables)
    }
    
    func directoryURL() -> URL {
        UITextPath.directoryURL(basePath: basePath, language: language)
    }

    func fileURL(forID id: String) -> URL {
        UITextPath.fileURL(basePath: basePath, language: language, file: id)
    }
    
    func resolvedFileURL(forID id: String) throws -> URL {
        let directory = directoryURL()
        let names = (try? loader.fileNames(inDirectory: directory)) ?? []
        let exactName = "\(id).cst"
        
        if names.contains(exactName) {
            if #available(macOS 13, *) {
                return directory.appending(path: exactName)
            } else {
                return directory.appendingPathComponent(exactName)
            }
        }
        
        let prefix = "\(id)_"
        if let prefixedName = names.first(where: {
            $0.hasPrefix(prefix) && $0.hasSuffix(".cst")
        }) {
            if #available(macOS 13, *) {
                return directory.appending(path: prefixedName)
            } else {
                return directory.appendingPathComponent(prefixedName)
            }
        }
        
        if #available(macOS 13, *) {
            throw UITextError.fileNotFound(directory.appending(path: exactName).path())
        } else {
            throw UITextError.fileNotFound(directory.appendingPathComponent(exactName).path)
        }
    }

}
