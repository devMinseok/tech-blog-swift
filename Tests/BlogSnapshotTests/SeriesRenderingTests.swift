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

  func testSeriesPostShowsTrailAndNeighbors() throws {
    let first = try post(part: 1, title: "첫 편", summary: "s")
    let second = try post(part: 2, title: "둘째 편", summary: "s")
    let third = try post(part: 3, title: "셋째 편", summary: "s")
    let catalog = SeriesCatalog(series: [try catalog(status: .ongoing).entries[0].series], posts: [first, second, third])
    let context = try XCTUnwrap(catalog.context(for: second))
    let html = PostDetailView().render(post: second, layout: layout, series: context)

    XCTAssertTrue(html.contains("href=\"/repo/series/teardown/\""))
    XCTAssertTrue(html.contains("href=\"/repo/series/teardown/spm/\""))
    XCTAssertTrue(html.contains("· 2편"))
    XCTAssertTrue(html.contains("← 1편"))
    XCTAssertTrue(html.contains("3편 →"))
    XCTAssertTrue(html.contains("href=\"/repo/posts/spm-1/\""))
    XCTAssertTrue(html.contains("href=\"/repo/posts/spm-3/\""))
    let trail = try XCTUnwrap(html.range(of: "series-trail"))
    let heading = try XCTUnwrap(html.range(of: "<h1>"))
    XCTAssertLessThan(trail.lowerBound, heading.lowerBound)
    let partNav = try XCTUnwrap(html.range(of: "part-nav"))
    let comments = try XCTUnwrap(html.range(of: "comments-title"))
    XCTAssertLessThan(partNav.lowerBound, comments.lowerBound)
  }

  func testFirstPartHasNoPrevious() throws {
    let first = try post(part: 1, title: "첫 편", summary: "s")
    let second = try post(part: 2, title: "둘째 편", summary: "s")
    let catalog = SeriesCatalog(series: [try catalog(status: .ongoing).entries[0].series], posts: [first, second])
    let html = PostDetailView().render(
      post: first, layout: layout, series: try XCTUnwrap(catalog.context(for: first)))
    XCTAssertFalse(html.contains("←"))
    XCTAssertTrue(html.contains("2편 →"))
  }

  func testStandalonePostUnchanged() throws {
    let html = PostDetailView().render(
      post: try post(part: 1, title: "첫 편", summary: "s"), layout: layout)
    XCTAssertFalse(html.contains("series-trail"))
    XCTAssertFalse(html.contains("part-nav"))
  }

  func testSinglePartTopicHasNoPartNavigation() throws {
    let only = try post(part: 1, title: "유일한 편", summary: "s")
    let catalog = SeriesCatalog(
      series: [try catalog(status: .completed).entries[0].series], posts: [only])
    let html = PostDetailView().render(
      post: only, layout: layout, series: try XCTUnwrap(catalog.context(for: only)))
    XCTAssertTrue(html.contains("series-trail"))
    XCTAssertFalse(html.contains("part-nav"))
  }

  func testSeriesTrailDoesNotInheritFlexNavigationLayout() throws {
    let stylesheet = URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
      .appendingPathComponent("Public/styles/site.css")
    let css = try String(contentsOf: stylesheet, encoding: .utf8)
    let rule = try XCTUnwrap(
      css.split(separator: "\n").first { $0.hasPrefix(".series-trail {") })
    XCTAssertTrue(rule.contains("display: block"))
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
