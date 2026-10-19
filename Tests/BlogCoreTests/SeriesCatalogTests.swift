import BlogCore
import Foundation
import XCTest

final class SeriesCatalogTests: XCTestCase {
  func testGroupsPartsInOrder() throws {
    let posts = try [post(part: 2), post(part: 1), post(part: 3)]
    let catalog = SeriesCatalog(series: [series(topics: ["spm"])], posts: posts)
    XCTAssertEqual(catalog.entries[0].topics[0].parts.map(\.membership?.part), [1, 2, 3])
  }

  func testHidesTopicsAndSeriesWithoutPublishedParts() throws {
    let catalog = SeriesCatalog(
      series: [
        series(topics: ["spm", "empty"]),
        series(slug: "wwdc", topics: ["swiftdata"]),
      ],
      posts: [try post(part: 1)]
    )
    XCTAssertEqual(catalog.entries.map(\.series.slug), ["teardown"])
    XCTAssertEqual(catalog.entries[0].topics.map(\.topic.slug), ["spm"])
  }

  func testOrdersByLatestPart() throws {
    let catalog = SeriesCatalog(
      series: [series(topics: ["a", "b"])],
      posts: [
        try post(topic: "a", part: 1, date: "2026-09-01"),
        try post(topic: "b", part: 1, date: "2026-10-01"),
      ]
    )
    XCTAssertEqual(catalog.entries[0].topics.map(\.topic.slug), ["b", "a"])
    XCTAssertEqual(catalog.entries[0].latestPublishedAt, BlogDate.parse("2026-10-01"))
  }

  func testNeighborsSkipHiddenParts() throws {
    let first = try post(part: 1)
    let third = try post(part: 3)
    let catalog = SeriesCatalog(series: [series(topics: ["spm"])], posts: [third, first])
    let context = try XCTUnwrap(catalog.context(for: third))
    XCTAssertEqual(context.part, 3)
    XCTAssertEqual(context.previous?.membership?.part, 1)
    XCTAssertNil(context.next)
    XCTAssertEqual(context.series.slug, "teardown")
    XCTAssertEqual(context.topic.slug, "spm")
  }

  func testContextIsNilForStandalonePost() throws {
    let standalone = BlogPost(
      id: "solo",
      title: "Solo",
      slug: "solo",
      publishedAt: try XCTUnwrap(BlogDate.parse("2026-09-01")),
      summary: "s",
      tags: [],
      isDraft: false,
      coverImage: nil,
      content: "c",
      sourceFile: "solo.md"
    )
    let catalog = SeriesCatalog(series: [series(topics: ["spm"])], posts: [standalone])
    XCTAssertNil(catalog.context(for: standalone))
    XCTAssertEqual(catalog.entries, [])
  }

  private func series(slug: String = "teardown", topics: [String]) -> Series {
    Series(
      slug: slug,
      title: slug,
      summary: "요약",
      introduction: "소개",
      topics: topics.map {
        Topic(
          slug: $0,
          title: $0,
          summary: "요약",
          status: .ongoing,
          introduction: "소개",
          sourceFile: "\(slug)/\($0).md"
        )
      },
      sourceFile: "\(slug)/_series.md"
    )
  }

  private func post(
    series: String = "teardown",
    topic: String = "spm",
    part: Int,
    date: String = "2026-09-01"
  ) throws -> BlogPost {
    BlogPost(
      id: "\(topic)-\(part)",
      title: "\(topic) \(part)",
      slug: "\(topic)-\(part)",
      publishedAt: try XCTUnwrap(BlogDate.parse(date)),
      summary: "s",
      tags: [],
      isDraft: false,
      coverImage: nil,
      content: "c",
      sourceFile: "\(topic)-\(part).md",
      membership: SeriesMembership(series: series, topic: topic, part: part)
    )
  }
}
