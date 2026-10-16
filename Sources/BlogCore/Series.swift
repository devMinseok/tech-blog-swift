import Foundation

public enum TopicStatus: String, Sendable, Equatable {
  case ongoing
  case completed
}

public struct Topic: Sendable, Equatable {
  public let slug: String
  public let title: String
  public let summary: String
  public let status: TopicStatus
  public let introduction: String
  public let sourceFile: String

  public init(
    slug: String,
    title: String,
    summary: String,
    status: TopicStatus,
    introduction: String,
    sourceFile: String
  ) {
    self.slug = slug
    self.title = title
    self.summary = summary
    self.status = status
    self.introduction = introduction
    self.sourceFile = sourceFile
  }
}

public struct Series: Sendable, Equatable {
  public let slug: String
  public let title: String
  public let summary: String
  public let introduction: String
  public let topics: [Topic]
  public let sourceFile: String

  public init(
    slug: String,
    title: String,
    summary: String,
    introduction: String,
    topics: [Topic],
    sourceFile: String
  ) {
    self.slug = slug
    self.title = title
    self.summary = summary
    self.introduction = introduction
    self.topics = topics
    self.sourceFile = sourceFile
  }
}
