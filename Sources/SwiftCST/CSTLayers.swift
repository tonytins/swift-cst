/// Directories of tables laid over one another, looked through in order.
///
/// Sims Steering Committee lays each person's tables over the global ones: a person's table 130
/// holds their own animations, and its empty values mean "use the global table's value". A lookup
/// here tries each layer from the first, so put the top layer, such as the person's, first.
///
/// Layers are plain values. Adding or removing one, such as a mod or a language, is changing
/// ``layers``, with nothing to undo in the others.
///
/// ```swift
/// let layers = CSTLayers([try CSTDirectory(contentsOf: ross), try CSTDirectory(contentsOf: global)])
/// layers.value(inTable: 130, atPosition: 19, treatingEmptyAsMissing: true)
/// ```
public struct CSTLayers: Sendable {
  /// The directories to look through, from the top layer down.
  public var layers: [CSTDirectory]

  /// Creates a stack of directories.
  ///
  /// - Parameter layers: The directories to look through, from the top layer down.
  public init(_ layers: [CSTDirectory]) {
    self.layers = layers
  }

  /// Returns the value for a key or name in the first layer whose table has it.
  ///
  /// - Parameters:
  ///   - id: The table's ID.
  ///   - key: The key or name to find, matched as ``CSTTable/value(forKey:)`` does.
  ///   - treatingEmptyAsMissing: Whether an empty value means "look in the next layer". By
  ///     default an empty value is returned, because most empty values are real empty text.
  /// - Returns: The value, or `nil` if no layer has one.
  public func value(
    inTable id: Int,
    forKey key: some CustomStringConvertible,
    treatingEmptyAsMissing: Bool = false
  ) -> String? {
    firstValue(treatingEmptyAsMissing: treatingEmptyAsMissing) { layer in
      layer.table(for: id)?.value(forKey: key)
    }
  }

  /// Returns the value at a position in the first layer whose table has a value there.
  ///
  /// Positions count every entry in a table from 0, as ``CSTTable/entries`` does, including
  /// entries with keys and entries never closed. A value never closed counts as missing.
  ///
  /// - Parameters:
  ///   - id: The table's ID.
  ///   - position: The entry's index among the table's entries, from 0.
  ///   - treatingEmptyAsMissing: Whether an empty value means "look in the next layer". By
  ///     default an empty value is returned, because most empty values are real empty text.
  /// - Returns: The value, or `nil` if no layer has one.
  public func value(
    inTable id: Int,
    atPosition position: Int,
    treatingEmptyAsMissing: Bool = false
  ) -> String? {
    firstValue(treatingEmptyAsMissing: treatingEmptyAsMissing) { layer in
      guard let entries = layer.table(for: id)?.entries, entries.indices.contains(position) else {
        return nil
      }
      return entries[position].value
    }
  }

  private func firstValue(
    treatingEmptyAsMissing: Bool,
    in lookUp: (CSTDirectory) -> String?
  ) -> String? {
    for layer in layers {
      if let value = lookUp(layer), !(treatingEmptyAsMissing && value.isEmpty) {
        return value
      }
    }
    return nil
  }
}
