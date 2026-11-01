import Foundation
import Testing

@testable import SwiftCST

struct UITextTests {
  @Test
  func readsBundledEnglishCatalogByDefault() async throws {
    let catalog = UIText()
    let message = try await catalog.text(for: 101, key: "newMail", variables: 5)
    let multiline = try await catalog.text(for: 102, key: "Multiline")

    #expect(message == "You have 5 new messages.")
    #expect(multiline.contains("\n\nQuisque vehicula"))
    #expect(multiline.contains("%1"))
  }

  @Test
  func readsLocalizedTextByFileIDAndKey() async throws {
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
    let greeting = try await catalog.text(for: 101, key: "welcome", variables: "World")
    let missing = try await catalog.text(for: 102, key: "welcome")

    #expect(greeting == "Hello World!")
    #expect(missing == "*** MISSING ***")
  }

  @Test
  func readsIntegerKeys() async throws {
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
    let entry = try await catalog.text(for: 101, key: 1)

    #expect(entry == "First entry.")
  }
}
