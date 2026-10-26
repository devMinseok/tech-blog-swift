import BlogCore
import BlogRouter
import BlogViews
import Foundation
import XCTest

final class MediumLayoutTests: XCTestCase {
  private let layout = PageLayout(
    configuration: SiteConfiguration(
      baseURL: "https://owner.github.io",
      basePath: "/repo",
      authorName: "Minseok",
      repository: "owner/repo"
    )
  )

  func testPostHeaderShowsBylineAfterTitle() throws {
    let html = PostDetailView().render(post: try post(coverImage: nil), layout: layout)
    let heading = try XCTUnwrap(html.range(of: "<h1>"))
    let byline = try XCTUnwrap(html.range(of: "class=\"byline\""))
    XCTAssertLessThan(heading.lowerBound, byline.lowerBound)
    XCTAssertTrue(html.contains("class=\"byline__avatar\" aria-hidden=\"true\">M</span>"))
    XCTAssertTrue(html.contains("class=\"byline__name\">Minseok</span>"))
    XCTAssertTrue(html.contains("1분 읽기"))
  }

  func testPostTagsFollowBody() throws {
    let html = PostDetailView().render(post: try post(coverImage: nil), layout: layout)
    let prose = try XCTUnwrap(html.range(of: "class=\"prose\""))
    let tags = try XCTUnwrap(html.range(of: "class=\"tag-cloud post-tags\""))
    XCTAssertLessThan(prose.lowerBound, tags.lowerBound)
  }

  func testPostCardShowsCoverThumbnail() throws {
    let html = PostListView().render(posts: [try post(coverImage: "/images/cover.png")], layout: layout)
    XCTAssertTrue(html.contains("post-card--with-cover"))
    XCTAssertTrue(html.contains("class=\"post-card__thumb\" src=\"/repo/images/cover.png\""))
  }

  func testPostCardWithoutCoverHasNoThumbnail() throws {
    let html = PostListView().render(posts: [try post(coverImage: nil)], layout: layout)
    XCTAssertFalse(html.contains("post-card__thumb"))
  }

  func testLayoutLoadsKoreanSerifFont() throws {
    let html = AboutView().render(layout: layout)
    XCTAssertTrue(html.contains("https://fonts.googleapis.com/css2?family=Noto+Serif+KR:wght@400;700&amp;display=swap"))
    let font = try XCTUnwrap(html.range(of: "fonts.googleapis.com/css2"))
    let site = try XCTUnwrap(html.range(of: "styles/site.css"))
    XCTAssertLessThan(font.lowerBound, site.lowerBound)
  }

  func testHomeQuoteStartsHiddenUntilFetched() throws {
    let html = HomeView().render(posts: [try post(coverImage: nil)], layout: layout)
    XCTAssertTrue(html.contains("<section class=\"hero container\" data-quote hidden>"))
    XCTAssertTrue(html.contains("<h1 class=\"hero__quote-text\"></h1>"))
    XCTAssertTrue(html.contains("<cite></cite>"))
    XCTAssertFalse(html.contains("id=\"quotes\""))
    let hero = try XCTUnwrap(html.range(of: "class=\"hero container\""))
    let recent = try XCTUnwrap(html.range(of: "최근 글"))
    XCTAssertLessThan(hero.lowerBound, recent.lowerBound)
  }

  func testSiteScriptFetchesQuoteAndRevealsOnlyOnSuccess() throws {
    let script = URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
      .appendingPathComponent("Public/scripts/site.js")
    let js = try String(contentsOf: script, encoding: .utf8)
    XCTAssertTrue(js.contains("https://korean-advice-open-api.vercel.app/api/advice"))
    XCTAssertTrue(js.contains("AbortController"))
    XCTAssertTrue(js.contains("hidden = false"))
  }

  private func post(coverImage: String?) throws -> BlogPost {
    BlogPost(
      id: "post",
      title: "Hello",
      slug: "hello",
      publishedAt: try XCTUnwrap(BlogDate.parse("2026-09-01")),
      summary: "Summary",
      tags: ["Swift"],
      isDraft: false,
      coverImage: coverImage,
      content: "Body",
      sourceFile: "post.md"
    )
  }
}
