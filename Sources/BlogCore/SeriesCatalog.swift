import Foundation

public struct TopicEntry: Sendable, Equatable {
  public let topic: Topic
  /// 공개된 편, `part` 오름차순.
  public let parts: [BlogPost]
  public let latestPublishedAt: Date
}

public struct SeriesEntry: Sendable, Equatable {
  public let series: Series
  public let topics: [TopicEntry]
  public let latestPublishedAt: Date
}

public struct PostSeriesContext: Sendable, Equatable {
  public let series: Series
  public let topic: Topic
  public let part: Int
  public let previous: BlogPost?
  public let next: BlogPost?

  public init(series: Series, topic: Topic, part: Int, previous: BlogPost?, next: BlogPost?) {
    self.series = series
    self.topic = topic
    self.part = part
    self.previous = previous
    self.next = next
  }
}

/// 공개된 글 기준으로 묶은 시리즈 목록. 공개된 편이 없는 주제와 주제가 없는 시리즈는 빠진다.
public struct SeriesCatalog: Sendable, Equatable {
  public let entries: [SeriesEntry]

  public init(series: [Series], posts: [BlogPost]) {
    entries =
      series.compactMap { series -> SeriesEntry? in
        let topics = series.topics.compactMap { topic -> TopicEntry? in
          let parts =
            posts
            .filter { $0.membership?.series == series.slug && $0.membership?.topic == topic.slug }
            .sorted { ($0.membership?.part ?? 0) < ($1.membership?.part ?? 0) }
          guard let latest = parts.map(\.publishedAt).max() else { return nil }
          return TopicEntry(topic: topic, parts: parts, latestPublishedAt: latest)
        }
        .sorted { newestFirst(($0.latestPublishedAt, $0.topic.slug), ($1.latestPublishedAt, $1.topic.slug)) }
        guard let latest = topics.first?.latestPublishedAt else { return nil }
        return SeriesEntry(series: series, topics: topics, latestPublishedAt: latest)
      }
      .sorted { newestFirst(($0.latestPublishedAt, $0.series.slug), ($1.latestPublishedAt, $1.series.slug)) }
  }

  public func context(for post: BlogPost) -> PostSeriesContext? {
    guard let membership = post.membership,
      let entry = entries.first(where: { $0.series.slug == membership.series }),
      let topic = entry.topics.first(where: { $0.topic.slug == membership.topic }),
      let index = topic.parts.firstIndex(where: { $0.id == post.id })
    else { return nil }

    return PostSeriesContext(
      series: entry.series,
      topic: topic.topic,
      part: membership.part,
      previous: index > 0 ? topic.parts[index - 1] : nil,
      next: index + 1 < topic.parts.count ? topic.parts[index + 1] : nil
    )
  }
}

private func newestFirst(_ lhs: (Date, String), _ rhs: (Date, String)) -> Bool {
  lhs.0 == rhs.0 ? lhs.1 < rhs.1 : lhs.0 > rhs.0
}
