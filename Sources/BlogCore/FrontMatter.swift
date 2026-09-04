import Foundation

public struct FrontMatter: Sendable, Equatable {
  public let values: [String: String]
  public let body: String

  public init(values: [String: String], body: String) {
    self.values = values
    self.body = body
  }

  public subscript(key: String) -> String? {
    values[key]
  }

  public static func parse(_ source: String, file: String) throws -> FrontMatter {
    let normalized = source.replacingOccurrences(of: "\r\n", with: "\n")
    guard normalized.hasPrefix("---\n") else {
      throw ContentError.missingFrontMatter(file: file)
    }

    let remainder = normalized.dropFirst(4)
    guard let end = remainder.range(of: "\n---\n") else {
      throw ContentError.missingFrontMatterTerminator(file: file)
    }

    let header = remainder[..<end.lowerBound]
    let body = remainder[end.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines)
    var values: [String: String] = [:]

    for (offset, line) in header.split(separator: "\n", omittingEmptySubsequences: false)
      .enumerated()
    {
      let rawLine = String(line)
      if rawLine.trimmingCharacters(in: .whitespaces).isEmpty || rawLine.hasPrefix("#") {
        continue
      }
      guard let separator = rawLine.firstIndex(of: ":") else {
        throw ContentError.invalidFrontMatterLine(
          file: file,
          line: offset + 2,
          value: rawLine
        )
      }

      let key = rawLine[..<separator].trimmingCharacters(in: .whitespaces)
      let value = rawLine[rawLine.index(after: separator)...]
        .trimmingCharacters(in: .whitespaces)
        .trimmingQuotes()

      guard !key.isEmpty else {
        throw ContentError.invalidFrontMatterLine(
          file: file,
          line: offset + 2,
          value: rawLine
        )
      }
      guard values[key] == nil else {
        throw ContentError.duplicateField(file: file, field: key)
      }
      values[key] = value
    }

    guard !body.isEmpty else {
      throw ContentError.emptyBody(file: file)
    }
    return FrontMatter(values: values, body: body)
  }
}

extension String {
  fileprivate func trimmingQuotes() -> String {
    guard count >= 2 else { return self }
    if (hasPrefix("\"") && hasSuffix("\"")) || (hasPrefix("'") && hasSuffix("'")) {
      return String(dropFirst().dropLast())
    }
    return self
  }
}
