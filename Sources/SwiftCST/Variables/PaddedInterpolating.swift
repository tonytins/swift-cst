/// How a number placeholder fills out a short number, following C's `printf`.
enum NumberPadding {
  /// `%3d`: at least this many characters, filled with spaces.
  case spaces(width: Int)

  /// `%03d`: at least this many characters including any sign, filled with zeros after the sign.
  case zeros(width: Int)

  /// `%.3d`: at least this many digits not including any sign.
  case digits(count: Int)
}

extension String {
  func padded(_ padding: NumberPadding) -> String {
    let sign = hasPrefix("-") ? "-" : ""
    let digits = dropFirst(sign.count)

    switch padding {
    case .spaces(let width):
      return String(repeating: " ", count: max(0, width - count)) + self
    case .zeros(let width):
      return sign + String(repeating: "0", count: max(0, width - count)) + digits
    case .digits(let digitCount):
      return sign + String(repeating: "0", count: max(0, digitCount - digits.count)) + digits
    }
  }
}
