import Foundation

// TODO: Remove "internal" keywords when UIText has been fully tested
internal class UIText {
    private var language: String
    private var basePath: String
    private var isDebug: Bool

    init(language: String, basePath: String, debug: Bool = false) {
        self.language = language
        self.basePath = basePath
        isDebug = debug
    }

    func getText(id: Int,
                 key: some CustomStringConvertible,
                 variables: any CustomStringConvertible...) async -> String
    {
        var langPath = languageDictionaryPath(for: language)

        guard fileSystemAvailable(at: langPath) else { return "\(langPath) not found." }

        guard let filePath = findLanguageFile(in: langPath, with: id) else {
            return "\(langPath) not found."
        }

        guard let content = readFileContent(at: filePath) else {
            return missingMessage
        }

        return await CST.parse(content, key: key, variables: variables)
    }

    private func findLanguageFile(in directory: String, with id: Int) -> String? {
        let fileManager = FileManager.default
        guard let bundlePath = try? fileManager.contentsOfDirectory(
            atPath: directory,
        ) else { return nil }

        let filePattern = "_\(id)_"
        let cstFile = bundlePath.first { file in
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
        let languageDir = "\(language).dir/"

        if isDebug {
            let fileManager = FileManager.default
            return fileManager.currentDirectoryPath.appending(languageDir)
        }

        return (basePath as NSString).appendingPathComponent(languageDir)
    }

    private func defaultBasePath() -> String {
        let uiTextDir = "uitext"

        if isDebug {
            let fileManager = FileManager.default
            return fileManager.currentDirectoryPath.appending(uiTextDir)
        }

        let bundlePath = Bundle.main.bundlePath
        return (bundlePath as NSString).appendingPathComponent(uiTextDir)
    }

    private func fileSystemAvailable(at path: String) -> Bool {
        FileManager.default.fileExists(atPath: path)
    }
}
