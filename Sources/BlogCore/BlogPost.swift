import Foundation

public struct BlogPost: Identifiable, Sendable, Equatable {
  public let id: String
  public let title: String
  public let slug: String
  public let publishedAt: Date
  public let summary: String
  public let tags: [String]
  public let isDraft: Bool
  public let coverImage: String?
  public let content: String
  public let sourceFile: String

  public init(
    id: String,
    title: String,
    slug: String,
    publishedAt: Date,
    summary: String,
    tags: [String],
    isDraft: Bool,
    coverImage: String?,
    content: String,
    sourceFile: String
  ) {
    self.id = id
    self.title = title
    self.slug = slug
    self.publishedAt = publishedAt
    self.summary = summary
    self.tags = tags
    self.isDraft = isDraft
    self.coverImage = coverImage
    self.content = content
    self.sourceFile = sourceFile
  }

  public var estimatedReadingMinutes: Int {
    let wordCount = content.split(whereSeparator: \.isWhitespace).count
    return max(1, Int(ceil(Double(wordCount) / 200)))
  }
}

public enum BlogDate {
  public static func parse(_ value: String) -> Date? {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "yyyy-MM-dd"
    formatter.isLenient = false
    guard let date = formatter.date(from: value), formatter.string(from: date) == value else {
      return nil
    }
    return date
  }

  public static func display(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "ko_KR")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "yyyy년 M월 d일"
    return formatter.string(from: date)
  }

  public static func machine(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.string(from: date)
  }
}
