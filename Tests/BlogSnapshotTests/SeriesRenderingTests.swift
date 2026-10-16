import BlogCore
import BlogRouter
import BlogViews
import Foundation
import XCTest

final class SeriesRenderingTests: XCTestCase {
  private let layout = PageLayout(
    configuration: SiteConfiguration(
      baseURL: "https://owner.github.io", basePath: "/repo", repository: "owner/repo"))

  func testSeriesPageShowsTopicCards() throws {
    let catalog = try catalog(status: .ongoing)
    let html = SeriesView().render(entry: catalog.entries[0], layout: layout)
    XCTAssertTrue(html.contains("href=\"/repo/series/teardown/spm/\""))
    XCTAssertTrue(html.contains("SPM 뜯어보기"))
    XCTAssertTrue(html.contains("2편 · 연재 중"))
    XCTAssertFalse(html.contains("Package.swift는 어떻게 읽히나"))
  }

  func testTopicPageListsPartsInOrder() throws {
    let catalog = try catalog(status: .completed)
    let entry = catalog.entries[0]
    let html = TopicView().render(series: entry, topic: entry.topics[0], layout: layout)
    let first = try XCTUnwrap(html.range(of: "Package.swift는 어떻게 읽히나"))
    let second = try XCTUnwrap(html.range(of: "의존성 버전은 어떻게 정해지나"))
    XCTAssertLessThan(first.lowerBound, second.lowerBound)
    XCTAssertTrue(html.contains("href=\"/repo/posts/spm-1/\""))
    XCTAssertTrue(html.contains("href=\"/repo/series/teardown/\""))
    XCTAssertTrue(html.contains("완결"))
    XCTAssertTrue(html.contains("1편"))
    XCTAssertTrue(html.contains("첫 편 요약"))
  }

  func testSeriesListEmptyState() {
    let html = SeriesListView().render(
      catalog: SeriesCatalog(series: [], posts: []), layout: layout)
    XCTAssertTrue(html.contains("아직 공개된 시리즈가 없습니다."))
  }

  func testSeriesListLinksToSeries() throws {
    let html = SeriesListView().render(catalog: try catalog(status: .ongoing), layout: layout)
    XCTAssertTrue(html.contains("href=\"/repo/series/teardown/\""))
    XCTAssertTrue(html.contains("뜯어보기"))
  }

  func testNavigationIncludesSeries() throws {
    let html = SeriesView().render(entry: try catalog(status: .ongoing).entries[0], layout: layout)
    XCTAssertTrue(html.contains("<a href=\"/repo/series/\" aria-current=\"page\">시리즈</a>"))
    let about = AboutView().render(layout: layout)
    XCTAssertTrue(about.contains("<a href=\"/repo/series/\">시리즈</a>"))
  }

  private func catalog(status: TopicStatus) throws -> SeriesCatalog {
    let topic = Topic(
      slug: "spm", title: "SPM 뜯어보기", summary: "Package.swift부터", status: status,
      introduction: "주제 소개", sourceFile: "teardown/spm.md")
    let series = Series(
      slug: "teardown", title: "뜯어보기", summary: "원초적인 걸 파봅니다.", introduction: "시리즈 소개",
      topics: [topic], sourceFile: "teardown/_series.md")
    let posts = [
      try post(part: 2, title: "의존성 버전은 어떻게 정해지나", summary: "둘째 편 요약"),
      try post(part: 1, title: "Package.swift는 어떻게 읽히나", summary: "첫 편 요약"),
    ]
    return SeriesCatalog(series: [series], posts: posts)
  }

  private func post(part: Int, title: String, summary: String) throws -> BlogPost {
    BlogPost(
      id: "spm-\(part)", title: title, slug: "spm-\(part)",
      publishedAt: try XCTUnwrap(BlogDate.parse("2026-09-0\(part)")), summary: summary,
      tags: [], isDraft: false, coverImage: nil, content: "본문", sourceFile: "spm-\(part).md",
      membership: SeriesMembership(series: "teardown", topic: "spm", part: part))
  }
}
