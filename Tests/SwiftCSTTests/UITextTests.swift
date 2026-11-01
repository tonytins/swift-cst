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
}
