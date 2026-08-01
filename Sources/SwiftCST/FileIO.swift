
import Foundation

protocol CSTFileLoader {
    func loadCST(at url: URL) throws -> String
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
    var files: [URL: String]
    
    func loadCST(at url: URL) throws -> String {
        guard let contents = files[url] else {
            throw UITextError.fileNotFound(url.futurePath())
        }
        
        return contents
    }
}
