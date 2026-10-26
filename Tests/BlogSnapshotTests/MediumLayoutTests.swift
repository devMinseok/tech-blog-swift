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

  func testHomeHeroIsShortAndShowsMotif() throws {
    let html = HomeView().render(posts: [try post(coverImage: nil)], layout: layout)
    XCTAssertTrue(html.contains("AI 딸깍으로 개발이 너무 편해져버린 나머지 원초적인 걸 파보기로 했습니다."))
    XCTAssertFalse(html.contains("SWIFT · ARCHITECTURE · NOTES"))
    XCTAssertFalse(html.contains("button-link"))
    let hero = try XCTUnwrap(html.range(of: "class=\"hero container\""))
    let recent = try XCTUnwrap(html.range(of: "최근 글"))
    XCTAssertLessThan(hero.lowerBound, recent.lowerBound)
  }

  func testAboutPageShowsEssayOnApps() throws {
    let html = AboutView().render(layout: layout)
    XCTAssertTrue(html.contains("<h2>앱은 사라질까?</h2>"))
    XCTAssertTrue(html.contains("본질 없는 앱이 사라진다고 생각한다."))
    XCTAssertTrue(html.contains("앱은 사라지지 않는다. 더 본질적인 방향으로 가고 있을 뿐이다."))
    XCTAssertTrue(html.contains("href=\"https://github.com/owner/repo\""))
    let essay = try XCTUnwrap(html.range(of: "앱은 사라질까?"))
    let principles = try XCTUnwrap(html.range(of: "이 블로그의 원칙"))
    XCTAssertLessThan(essay.lowerBound, principles.lowerBound)
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
