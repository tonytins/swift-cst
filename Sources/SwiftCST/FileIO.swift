import Foundation
import FutureFoundations

protocol CSTFileLoader {
    func loadCST(at url: URL) throws -> String
    func fileNames(inDirectory url: URL) throws -> [String]
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
    
    func fileNames(inDirectory url: URL) throws -> [String] {
        do {
            return try fileManager.contentsOfDirectory(atPath: url.futurePath())
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
    
    func fileNames(inDirectory url: URL) throws -> [String] {
        let directoryPath = url.futurePath()
        
        return files.keys
            .filter {
                $0.deletingLastPathComponent().futurePath() == directoryPath
            }
            .map {
                $0.lastPathComponent
            }
        
    }
}

struct UITextPath {
    static let uitext = "uitext"
    
    static func directoryURL(basePath: String, language: String) -> URL {
        let base = URL(fileURLWithPath: basePath)
        
        if #available(macOS 13, *) {
            return base.appending(path: uitext)
                .appending(path: "\(language).cst")
        } else {
            return base.appendingPathComponent(uitext)
                .appendingPathComponent("\(language).cst")
        }
    }
    
    static func fileURL(basePath: String, language: String, file: String) -> URL {
        let directory = directoryURL(basePath: basePath, language: language)
        
        if #available(macOS 13, *) {
            return directory
                .appending(path: uitext)
                .appending(path: "\(file).cst")
        } else {
            return directory
                .appendingPathExtension(uitext)
                .appendingPathComponent("\(file).cst")
        }
    }
}
