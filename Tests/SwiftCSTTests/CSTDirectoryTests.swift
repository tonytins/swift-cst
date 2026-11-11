import Foundation
import Testing

@testable import SwiftCST

struct CSTDirectoryTests {
  /// Writes files to a new temporary directory, runs `body`, then removes the directory.
  private func withDirectory(
    _ files: [String: Data],
    body: (URL) throws -> Void
  ) throws {
    let directory = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }

    for (name, data) in files {
      try data.write(to: directory.appendingPathComponent(name))
    }

    try body(directory)
  }

  @Test(arguments: [
    ("#128#Animations.cst", 128),
    ("_101_strings.cst", 101),
    ("#7#.CST", 7),
    ("_0_zero.cst", 0),
  ])
  func readsTableIDsFromBothNamingPatterns(fileName: String, id: Int) {
    #expect(CSTDirectory.tableID(fromFileName: fileName) == id)
  }

  @Test(arguments: [
    "gamecompdrawacard.cst", "#128.cst", "#12a#name.cst", "##name.cst", "_1#name.cst",
    "#128#Animations.txt", "_-1_negative.cst",
  ])
  func ignoresOtherFileNames(fileName: String) {
    #expect(CSTDirectory.tableID(fromFileName: fileName) == nil)
  }

  @Test
  func readsEveryTableInADirectory() throws {
    try withDirectory([
      "#128#Animations.cst": Data("^adult-tantrum^\tAnimMotiveTantrum".utf8),
      "_101_strings.cst": Data("1 ^one^".utf8),
      "notes.txt": Data("not a table".utf8),
      "credits.cst": Data("1 ^ignored^".utf8),
    ]) { url in
      let directory = try CSTDirectory(contentsOf: url)

      #expect(directory.tables.keys.sorted() == [101, 128])
      #expect(directory.table(for: 128)?.entries.first?.value == "adult-tantrum")
      #expect(directory.table(for: 101)?.value(forKey: 1) == "one")
      #expect(directory.problems.isEmpty)
    }
  }

  @Test
  func keepsTheFirstFileForARepeatedID() throws {
    try withDirectory([
      "#5#first.cst": Data("^first^".utf8),
      "#5#second.cst": Data("^second^".utf8),
    ]) { url in
      let directory = try CSTDirectory(contentsOf: url)

      #expect(directory.table(for: 5)?.entries.first?.value == "first")
      #expect(directory.problems == [.repeatedTable(5, file: "#5#second.cst")])
    }
  }

  @Test
  func decodesWindows1252() throws {
    try withDirectory(["_1_credits.cst": Data([0x31, 0x20, 0x5E, 0xE9, 0x5E])]) { url in
      let directory = try CSTDirectory(contentsOf: url)

      #expect(directory.table(for: 1)?.value(forKey: 1) == "é")
    }
  }

  @Test
  func throwsForAMissingDirectory() {
    let missing = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString, isDirectory: true)

    #expect(throws: (any Error).self) { try CSTDirectory(contentsOf: missing) }
  }
}

struct CSTLayersTests {
  private let person = CSTDirectory(tables: [
    130: CSTTable(
      """
      ^^
      ^ross-standing-loop^
      name ^ross^
      blank ^^
      """
    )
  ])

  private let global = CSTDirectory(tables: [
    130: CSTTable(
      """
      ^adult-haveaccident^
      ^duchess-standing-loop^
      name ^global^
      blank ^global blank^
      only ^only global^
      """
    ),
    128: CSTTable("^global only table^"),
  ])

  @Test
  func theTopLayerWins() {
    let layers = CSTLayers([person, global])

    #expect(layers.value(inTable: 130, atPosition: 1) == "ross-standing-loop")
    #expect(layers.value(inTable: 130, forKey: "name") == "ross")
  }

  @Test
  func emptyValuesAreReturnedUnlessTheCallerAsks() {
    let layers = CSTLayers([person, global])

    #expect(layers.value(inTable: 130, atPosition: 0) == "")
    #expect(layers.value(inTable: 130, forKey: "blank") == "")
    #expect(
      layers.value(inTable: 130, atPosition: 0, treatingEmptyAsMissing: true)
        == "adult-haveaccident"
    )
    #expect(
      layers.value(inTable: 130, forKey: "blank", treatingEmptyAsMissing: true) == "global blank"
    )
  }

  @Test
  func missingValuesAndTablesFallThrough() {
    let layers = CSTLayers([person, global])

    #expect(layers.value(inTable: 130, forKey: "only") == "only global")
    #expect(layers.value(inTable: 130, atPosition: 4) == "only global")
    #expect(layers.value(inTable: 128, atPosition: 0) == "global only table")
  }

  @Test
  func missesReturnNil() {
    let layers = CSTLayers([person, global])

    #expect(layers.value(inTable: 130, forKey: "absent") == nil)
    #expect(layers.value(inTable: 130, atPosition: 5) == nil)
    #expect(layers.value(inTable: 130, atPosition: -1) == nil)
    #expect(layers.value(inTable: 999, atPosition: 0) == nil)
    #expect(CSTLayers([]).value(inTable: 130, atPosition: 0) == nil)
  }

  @Test
  func anUnclosedValueFallsThrough() {
    let broken = CSTDirectory(tables: [130: CSTTable("^never closed")])

    #expect(CSTLayers([broken, global]).value(inTable: 130, atPosition: 0) == "adult-haveaccident")
  }

  @Test
  func removingALayerLeavesTheOthersAsTheyWere() {
    var layers = CSTLayers([person, global])
    layers.layers.removeFirst()

    #expect(layers.value(inTable: 130, atPosition: 1) == "duchess-standing-loop")
  }

  /// Lays Ross's tables over the global ones in a local Sims Steering Committee install, when
  /// `SSC_GAME_DIR` is set.
  @Test
  func laysAPersonOverTheGlobalTablesOfALocalSteeringCommitteeInstall() throws {
    guard let install = ProcessInfo.processInfo.environment["SSC_GAME_DIR"] else {
      return
    }

    let scenario = URL(fileURLWithPath: install).appendingPathComponent("DATA/TDSScen")
    let global = try CSTDirectory(contentsOf: scenario.appendingPathComponent("Global/Global.dir"))
    let ross = try CSTDirectory(contentsOf: scenario.appendingPathComponent("Objects/ross.dir"))
    let layers = CSTLayers([ross, global])

    #expect(global.problems.isEmpty)
    #expect(ross.problems.isEmpty)

    // Ross's own animation replaces the global placeholder in the same slot.
    #expect(CSTLayers([global]).value(inTable: 130, atPosition: 66) == "duchess-standing-loop")
    #expect(layers.value(inTable: 130, atPosition: 66) == "ross-standing-loop")

    // Ross's blank slot is filled in from the global table only when asked.
    #expect(layers.value(inTable: 130, atPosition: 20) == "")
    #expect(
      layers.value(inTable: 130, atPosition: 20, treatingEmptyAsMissing: true)
        == "adult-haveaccident"
    )

    // Ross has no table 128, so the global one answers.
    #expect(layers.value(inTable: 128, atPosition: 1) == "adult-haveaccident")
  }
}
