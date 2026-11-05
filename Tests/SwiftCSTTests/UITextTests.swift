import Foundation
import Testing

@testable import SwiftCST

struct UITextTests {
  @Test
  func defaultsToExecutableAdjacentCatalogDirectory() {
    let executableDirectory =
      Bundle.main.executableURL?.deletingLastPathComponent()
      ?? URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
    let catalog = UIText()

    #expect(
      catalog.basePath
        == executableDirectory.appendingPathComponent("uitext", isDirectory: true)
    )
  }

  @Test
  func readsEnglishCatalogFixture() throws {
    let resourceURL = try #require(Bundle.module.resourceURL)
    let catalog = UIText(
      basePath: resourceURL.appendingPathComponent("uitext", isDirectory: true)
    )
    let message = try catalog.text(for: 101, key: "newMail", variables: 5)
    let multiline = try catalog.text(for: 102, key: "Multiline")

    #expect(message == "You have 5 new messages.")
    #expect(multiline.contains("\n\nQuisque vehicula"))
    #expect(multiline.contains("%1"))
  }

  @Test
  func readsLocalizedTextByFileIDAndKey() throws {
    let basePath = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let languageDirectory = basePath.appendingPathComponent("english.dir", isDirectory: true)
    try FileManager.default.createDirectory(
      at: languageDirectory,
      withIntermediateDirectories: true
    )
    defer { try? FileManager.default.removeItem(at: basePath) }

    try "welcome ^Hello %s!^".write(
      to: languageDirectory.appendingPathComponent("_101_messages.cst"),
      atomically: true,
      encoding: .utf8
    )

    let catalog = UIText(basePath: basePath)
    let greeting = try catalog.text(for: 101, key: "welcome", variables: "World")
    let missing = try catalog.text(for: 102, key: "welcome")

    #expect(greeting == "Hello World!")
    #expect(missing == "*** MISSING ***")
  }

  @Test
  func fallsBackToBundleResourcesWhenExternalCatalogIsMissing() throws {
    let resourceURL = try #require(Bundle.module.resourceURL)
    let basePath = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let languageDirectory = basePath.appendingPathComponent("english.dir", isDirectory: true)
    try FileManager.default.createDirectory(
      at: languageDirectory,
      withIntermediateDirectories: true
    )
    defer { try? FileManager.default.removeItem(at: basePath) }

    let catalog = UIText(
      language: "english",
      basePath: basePath,
      fallbackPath: resourceURL.appendingPathComponent("uitext", isDirectory: true)
    )
    let message = try catalog.text(for: 101, key: "newMail", variables: 5)

    #expect(message == "You have 5 new messages.")
  }

  @Test
  func prefersExternalCatalogOverBundleResources() throws {
    let resourceURL = try #require(Bundle.module.resourceURL)
    let basePath = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let languageDirectory = basePath.appendingPathComponent("english.dir", isDirectory: true)
    try FileManager.default.createDirectory(
      at: languageDirectory,
      withIntermediateDirectories: true
    )
    defer { try? FileManager.default.removeItem(at: basePath) }

    try "newMail ^External catalog.^".write(
      to: languageDirectory.appendingPathComponent("_101_override.cst"),
      atomically: true,
      encoding: .utf8
    )

    let catalog = UIText(
      language: "english",
      basePath: basePath,
      fallbackPath: resourceURL.appendingPathComponent("uitext", isDirectory: true)
    )
    let message = try catalog.text(for: 101, key: "newMail")

    #expect(message == "External catalog.")
  }

  @Test
  func readsIntegerKeys() throws {
    let basePath = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let languageDirectory = basePath.appendingPathComponent("english.dir", isDirectory: true)
    try FileManager.default.createDirectory(
      at: languageDirectory,
      withIntermediateDirectories: true
    )
    defer { try? FileManager.default.removeItem(at: basePath) }

    try "1 ^First entry.^".write(
      to: languageDirectory.appendingPathComponent("_101_messages.cst"),
      atomically: true,
      encoding: .utf8
    )

    let catalog = UIText(basePath: basePath)
    let entry = try catalog.text(for: 101, key: 1)

    #expect(entry == "First entry.")
  }

  @Test
  func asyncLookupCompatibilityOverload() async throws {
    let resourceURL = try #require(Bundle.module.resourceURL)
    let catalog = UIText(
      basePath: resourceURL.appendingPathComponent("uitext", isDirectory: true)
    )
    let message = try await catalog.text(for: 101, key: "newMail", variables: 5)

    #expect(message == "You have 5 new messages.")
  }

  /// Runs `body` with a catalog holding `files`, given by file name.
  private func withCatalog(
    _ files: [String: Data],
    body: (UIText, URL) throws -> Void
  ) throws {
    let basePath = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let languageDirectory = basePath.appendingPathComponent("english.dir", isDirectory: true)
    try FileManager.default.createDirectory(
      at: languageDirectory,
      withIntermediateDirectories: true
    )
    defer { try? FileManager.default.removeItem(at: basePath) }

    for (name, data) in files {
      try data.write(to: languageDirectory.appendingPathComponent(name))
    }

    try body(UIText(basePath: basePath), languageDirectory)
  }

  private func withCatalog(_ files: [String: String], body: (UIText, URL) throws -> Void) throws {
    try withCatalog(files.mapValues { Data($0.utf8) }, body: body)
  }

  @Test
  func readsTheSpecificationExampleByKeyNameAndPosition() throws {
    let example = try specificationExample()

    try withCatalog(["_1_example.cst": example]) { catalog, _ throws in
      let expected = [
        ("1", "A value after its key"),
        ("2", "An indented key"),
        ("3", "A key above its value"),
        ("4", "A value that runs\nacross lines"),
        ("ok button", "A key with spaces"),
        ("kErrNoFood", "A name above its value"),
        ("5", "A name above its value"),
        ("A note for translators.", "A value with a note above it"),
        ("6", "A value with a note above it"),
        ("7", "A value on its own"),
        ("8", "Another value on its own"),
      ]

      for (key, value) in expected {
        #expect(try catalog.text(for: 1, key: key) == value)
      }
    }
  }

  @Test
  func writtenKeysWinOverPositions() throws {
    let table = """
      1 ^written^
      ^position 1^
      ^position 2^
      """

    try withCatalog(["_1_keys.cst": table]) { catalog, _ throws in
      #expect(try catalog.text(for: 1, key: 1) == "written")
      #expect(try catalog.text(for: 1, key: 2) == "position 2")
      #expect(try catalog.text(for: 1, key: 0) == "*** MISSING ***")
      #expect(try catalog.text(for: 1, key: "02") == "*** MISSING ***")
      #expect(try catalog.text(for: 1, key: 3) == "*** MISSING ***")
    }
  }

  @Test
  func anUnclosedValueStillCountsItsPosition() throws {
    let table = """
      ^unfinished
      ^second^
      """

    try withCatalog(["_1_broken.cst": table]) { catalog, _ throws in
      #expect(try catalog.text(for: 1, key: 0) == "*** MISSING ***")
      #expect(try catalog.text(for: 1, key: 1) == "second")
      #expect(try catalog.table(for: 1)?.problems == [.unclosedValue(line: 1)])
    }
  }

  @Test
  func readsWindows1252AndByteOrderMarks() throws {
    let files = [
      "_1_legacy.cst": Data("1 ^".utf8) + Data([0x93, 0x68, 0x69, 0x94]) + Data("^".utf8),
      "_2_marked.cst": Data([0xEF, 0xBB, 0xBF]) + Data("1 ^marked^".utf8),
      "_3_invalid.cst": Data("1 ^".utf8) + Data([0x81, 0xC0]) + Data("^\n2 ^fine^".utf8),
    ]

    try withCatalog(files) { catalog, _ throws in
      #expect(try catalog.text(for: 1, key: 1) == "\u{201C}hi\u{201D}")
      #expect(try catalog.text(for: 2, key: 1) == "marked")
      #expect(try catalog.text(for: 3, key: 2) == "fine")
    }
  }

  @Test
  func followsReferencesBetweenTables() throws {
    let references = """
      1 ^\u{2}<cst><cst_id>2</cst_id><string_id>1</string_id></cst>^
      2 ^\u{2}<cst><cst_id>2</cst_id><string_id>2</string_id><string arg="1">%s</string></cst>^
      3 ^\u{2}<cst><cst_id>2</cst_id><string_id>0</string_id></cst>^
      4 ^\u{2}<cst><cst_id>2</cst_id><string_id>9</string_id></cst>^
      5 ^\u{2}<cst><cst_id>9</cst_id><string_id>1</string_id></cst>^
      6 ^\u{2}<cst><cst_id>1</cst_id><string_id>6</string_id></cst>^
      7 ^\u{2}<cst>not a reference^
      """
    let targets = """
      ^at position 0^
      1 ^target^
      2 ^Hello %s^
      """

    try withCatalog(["_1_refs.cst": references, "_2_targets.cst": targets]) { catalog, _ throws in
      #expect(try catalog.text(for: 1, key: 1) == "target")
      #expect(try catalog.text(for: 1, key: 2, variables: "World") == "Hello World")
      #expect(try catalog.text(for: 1, key: 3) == "at position 0")
      #expect(try catalog.text(for: 1, key: 4) == "*** MISSING ***")
      #expect(try catalog.text(for: 1, key: 5) == "*** MISSING ***")
      #expect(try catalog.text(for: 1, key: 6) == "*** MISSING ***")
      #expect(try catalog.text(for: 1, key: 7) == "\u{2}<cst>not a reference")
    }
  }

  @Test
  func textIfPresentFindsWhatTextFinds() throws {
    let table = """
      greeting ^Hello %s!^
      ^at position 1^
      """

    try withCatalog(["_1_table.cst": table]) { catalog, _ throws in
      #expect(
        try catalog.textIfPresent(for: 1, key: "greeting", variables: "World") == "Hello World!")
      #expect(try catalog.textIfPresent(for: 1, key: 1) == "at position 1")
    }
  }

  @Test
  func textIfPresentReportsEveryKindOfMissAsNil() throws {
    let references = """
      1 ^\u{2}<cst><cst_id>2</cst_id><string_id>9</string_id></cst>^
      2 ^\u{2}<cst><cst_id>9</cst_id><string_id>1</string_id></cst>^
      3 ^\u{2}<cst><cst_id>1</cst_id><string_id>3</string_id></cst>^
      unfinished ^never closed
      """

    try withCatalog(["_1_refs.cst": references, "_2_targets.cst": "1 ^target^"]) {
      catalog, _ throws in
      #expect(try catalog.textIfPresent(for: 9, key: 1) == nil, "Missing table")
      #expect(try catalog.textIfPresent(for: 2, key: "nope") == nil, "Missing key")
      #expect(try catalog.textIfPresent(for: 1, key: "unfinished") == nil, "Unclosed value")
      #expect(try catalog.textIfPresent(for: 1, key: 1) == nil, "Missing reference target")
      #expect(try catalog.textIfPresent(for: 1, key: 2) == nil, "Reference to a missing table")
      #expect(try catalog.textIfPresent(for: 1, key: 3) == nil, "Reference chain")
      #expect(try catalog.text(for: 1, key: 3) == "*** MISSING ***")
    }
  }

  @Test
  func textIfPresentThrowsWhenAFileCannotBeRead() throws {
    try withCatalog([:] as [String: String]) { catalog, directory throws in
      // A directory with a table's name exists but can't be read as one.
      try FileManager.default.createDirectory(
        at: directory.appendingPathComponent("_1_table.cst"),
        withIntermediateDirectories: false
      )

      #expect(throws: (any Error).self) { try catalog.textIfPresent(for: 1, key: 1) }
      #expect(throws: (any Error).self) { try catalog.text(for: 1, key: 1) }
    }
  }

  /// Runs `body` with a temporary `gamedata` directory holding `directories`, each given by its
  /// path under `gamedata` and holding one table, `_1_table.cst`.
  private func withGameData(
    _ directories: [String: String],
    body: (URL) throws -> Void
  ) throws {
    let gameData = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: gameData, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: gameData) }

    for (path, table) in directories {
      let directory = gameData.appendingPathComponent(path, isDirectory: true)
      try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
      try Data(table.utf8).write(to: directory.appendingPathComponent("_1_table.cst"))
    }

    try body(gameData)
  }

  @Test
  func gameDataReadsEitherInstallLayout() throws {
    try withGameData(["uitext/english.dir": "1 ^New & Improved^"]) { gameData throws in
      let catalog = UIText(gameData: gameData)

      #expect(catalog.language == "english")
      #expect(try catalog.textIfPresent(for: 1, key: 1) == "New & Improved")
    }

    try withGameData(["uitext.dir": "1 ^base game^"]) { gameData throws in
      let catalog = UIText(gameData: gameData)

      #expect(catalog.language == "uitext")
      #expect(try catalog.textIfPresent(for: 1, key: 1) == "base game")
    }
  }

  @Test
  func gameDataPrefersTheLanguageDirectory() throws {
    let directories = [
      "uitext/english.dir": "1 ^English^",
      "uitext/swedish.dir": "1 ^Swedish^",
      "uitext.dir": "1 ^single language^",
    ]

    try withGameData(directories) { gameData throws in
      #expect(try UIText(gameData: gameData).textIfPresent(for: 1, key: 1) == "English")
      #expect(
        try UIText(gameData: gameData, language: "swedish").textIfPresent(for: 1, key: 1)
          == "Swedish"
      )
      #expect(
        try UIText(gameData: gameData, language: "french").textIfPresent(for: 1, key: 1)
          == "single language"
      )
    }
  }

  @Test
  func gameDataMissesWithoutEitherDirectory() throws {
    try withGameData([:]) { gameData throws in
      #expect(try UIText(gameData: gameData).textIfPresent(for: 1, key: 1) == nil)
    }
  }

  @Test
  func theCoreLeavesReferencesAlone() {
    let reference = "\u{2}<cst><cst_id>2</cst_id><string_id>1</string_id></cst>"

    #expect(CSTTable("1 ^\(reference)^").value(forKey: 1) == reference)
  }

  @Test
  func readsEachTableOnce() throws {
    try withCatalog(["_1_table.cst": "1 ^original^"]) { catalog, directory throws in
      #expect(try catalog.text(for: 1, key: 1) == "original")

      let copy = catalog
      try FileManager.default.removeItem(at: directory.appendingPathComponent("_1_table.cst"))

      #expect(try catalog.text(for: 1, key: 1) == "original")
      #expect(try copy.text(for: 1, key: 1) == "original")
    }
  }

  @Test
  func findsATableAddedAfterAFailedLookup() throws {
    try withCatalog(["_1_table.cst": "1 ^one^"]) { catalog, directory throws in
      #expect(try catalog.table(for: 2) == nil)

      try Data("1 ^two^".utf8).write(to: directory.appendingPathComponent("_2_table.cst"))

      #expect(try catalog.text(for: 2, key: 1) == "two")
    }
  }

  @Test
  func sharesLoadedTablesAcrossConcurrentLookups() async throws {
    let resourceURL = try #require(Bundle.module.resourceURL)
    let catalog = UIText(basePath: resourceURL.appendingPathComponent("uitext", isDirectory: true))

    try await withThrowingTaskGroup(of: String.self) { group in
      for _ in 0..<200 {
        group.addTask { try catalog.text(for: 101, key: "newMail", variables: 5) }
      }

      for try await message in group {
        #expect(message == "You have 5 new messages.")
      }
    }
  }

  @Test
  func readsTheEarlierSingleLanguageLayout() throws {
    let gameData = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let directory = gameData.appendingPathComponent("uitext.dir", isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: gameData) }

    try Data("1 ^base game^".utf8).write(to: directory.appendingPathComponent("_1_table.cst"))

    #expect(try UIText(language: "uitext", basePath: gameData).text(for: 1, key: 1) == "base game")
  }

  /// Reads every table of a local install, when its environment variable is set.
  @Test(arguments: ["TSO_BETA_DIR", "TSO_CLASSIC_DIR", "TSO_GAME_DIR"])
  func readsEveryTableOfALocalInstall(variable: String) throws {
    guard let install = ProcessInfo.processInfo.environment[variable] else {
      return
    }

    let gameData = URL(fileURLWithPath: install).appendingPathComponent("gamedata")
    let catalog = UIText(gameData: gameData)
    let directory = catalog.basePath.appendingPathComponent("\(catalog.language).dir")
    let tableIDs = try FileManager.default.contentsOfDirectory(atPath: directory.path)
      .compactMap { $0.first == "_" ? Int($0.dropFirst().prefix { $0 != "_" }) : nil }

    #expect(!tableIDs.isEmpty)

    var valueCount = 0
    for id in tableIDs {
      let table = try #require(try catalog.table(for: id))
      var seenKeys: Set<String> = []

      for (position, entry) in table.entries.enumerated() {
        let value = try #require(entry.value)
        let key = entry.key ?? String(position)
        guard seenKeys.insert(key).inserted else {
          continue
        }

        let text = try catalog.text(for: id, key: key)

        valueCount += 1
        #expect(text != "*** MISSING ***", "Table \(id), key \(key)")
        #expect(try catalog.textIfPresent(for: id, key: key) == text, "Table \(id), key \(key)")

        if value.hasPrefix("\u{2}") {
          #expect(!text.hasPrefix("\u{2}"), "Table \(id), key \(key)")
        } else {
          #expect(text == CST.format(value, with: []), "Table \(id), key \(key)")
        }
      }
    }

    #expect(valueCount > 0)
  }
}
