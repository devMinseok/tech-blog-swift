import Foundation

public struct Quote: Sendable, Equatable, Codable {
  public let text: String
  public let source: String

  public init(text: String, source: String) {
    self.text = text
    self.source = source
  }
}

/// `Content/quotes.md`를 읽습니다. 한 줄에 하나씩 `- 문장 — 출처` 형식이며 `#` 줄과 빈 줄은 건너뜁니다.
public struct QuoteLoader: Sendable {
  public init() {}

  public func loadQuotes(from file: URL) throws -> [Quote] {
    guard FileManager.default.fileExists(atPath: file.path) else { return [] }
    return try parse(String(contentsOf: file, encoding: .utf8))
  }

  public func parse(_ source: String) throws -> [Quote] {
    var quotes: [Quote] = []
    for (offset, rawLine) in source.replacingOccurrences(of: "\r\n", with: "\n")
      .split(separator: "\n", omittingEmptySubsequences: false)
      .enumerated()
    {
      let line = rawLine.trimmingCharacters(in: .whitespaces)
      if line.isEmpty || line.hasPrefix("#") { continue }

      var body = Substring(line)
      if body.hasPrefix("- ") { body = body.dropFirst(2) }
      guard let separator = body.range(of: " — ", options: .backwards) else {
        throw ContentError.invalidQuote(line: offset + 1, value: line)
      }
      let text = body[..<separator.lowerBound].trimmingCharacters(in: .whitespaces)
      let author = body[separator.upperBound...].trimmingCharacters(in: .whitespaces)
      guard !text.isEmpty, !author.isEmpty else {
        throw ContentError.invalidQuote(line: offset + 1, value: line)
      }
      quotes.append(Quote(text: text, source: author))
    }
    return quotes
  }
}
