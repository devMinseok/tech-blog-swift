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

  func testHomeHeroShowsFirstQuoteAndEmbedsAll() throws {
    let quotes = [
      Quote(text: "Talk is cheap. Show me the code.", source: "Linus Torvalds"),
      Quote(text: "What I cannot create, I do not understand.", source: "Richard Feynman"),
    ]
    let html = HomeView().render(posts: [try post(coverImage: nil)], quotes: quotes, layout: layout)
    XCTAssertTrue(
      html.contains("<h1 class=\"hero__quote-text\">Talk is cheap. Show me the code.</h1>")
    )
    XCTAssertFalse(html.contains("visually-hidden"))
    XCTAssertTrue(html.contains("<cite>Linus Torvalds</cite>"))
    XCTAssertTrue(html.contains("<script type=\"application/json\" id=\"quotes\">"))
    XCTAssertTrue(html.contains("What I cannot create, I do not understand."))
    XCTAssertFalse(html.contains("button-link"))
    let hero = try XCTUnwrap(html.range(of: "class=\"hero container\""))
    let recent = try XCTUnwrap(html.range(of: "최근 글"))
    XCTAssertLessThan(hero.lowerBound, recent.lowerBound)
  }

  func testAboutPageIntroducesAuthor() throws {
    let html = AboutView().render(layout: layout)
    XCTAssertTrue(html.contains("<h1>나에 대해서</h1>"))
    XCTAssertTrue(html.contains("<h2>아이폰도 맥북도 없던 고1</h2>"))
    XCTAssertTrue(html.contains("<h2>결국 사용자를 위해</h2>"))
    XCTAssertTrue(html.contains("<h2>요즘 공부하는 것</h2>"))
    XCTAssertTrue(html.contains("<h2>달리는 시간</h2>"))
    XCTAssertTrue(html.contains("href=\"/repo/series/\""))
    XCTAssertTrue(html.contains("href=\"https://github.com/owner\""))
    XCTAssertTrue(html.contains("href=\"https://github.com/owner/repo\""))
  }

  func testEmbeddedQuotesCannotCloseScriptTag() throws {
    let quotes = [Quote(text: "</script><b>bold</b>", source: "Tester")]
    let html = HomeView().render(posts: [], quotes: quotes, layout: layout)
    let json = try XCTUnwrap(html.range(of: "id=\"quotes\">"))
    XCTAssertFalse(html[json.upperBound...].hasPrefix("[{\"source\":\"Tester\",\"text\":\"</script>"))
    XCTAssertTrue(html.contains("<\\/script>"))
  }

  func testHomeWithoutQuotesShowsTagline() throws {
    let html = HomeView().render(posts: [], quotes: [], layout: layout)
    XCTAssertTrue(html.contains("배운 것을 오래 남기는 개발 기록"))
    XCTAssertFalse(html.contains("id=\"quotes\""))
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
