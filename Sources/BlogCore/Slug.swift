import Foundation

public enum Slug {
  public static func isValid(_ value: String) -> Bool {
    guard
      !value.isEmpty,
      value.first?.isASCIILetterOrNumber == true,
      value.last?.isASCIILetterOrNumber == true,
      !value.contains("--")
    else { return false }

    return value.allSatisfy { character in
      character.isASCIILetterOrNumber || character == "-"
    } && value == value.lowercased()
  }
}

extension Character {
  fileprivate var isASCIILetterOrNumber: Bool {
    guard unicodeScalars.count == 1, let value = unicodeScalars.first?.value else { return false }
    return (97...122).contains(value) || (48...57).contains(value)
  }
}
