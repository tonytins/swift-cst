import Foundation

extension String {
    func padded(toWidth width: Int) -> String {
        guard width > 0, count < width else { return self }
        
        return String(repeating: "0", count: width - count) + self
    }
}
