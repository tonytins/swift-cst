import Foundation

extension URL {
    
    /// Return URL.path for macOS 12 and earlier
    func futurePath(percentEncoded: Bool = true) -> String {
        if #available(macOS 13, *) {
            return path(percentEncoded: percentEncoded)
        } else {
            return path
        }
    }
}
