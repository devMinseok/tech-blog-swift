import BlogCore
import BlogRouter
import BlogViews
import Foundation
import XCTest

final class ViewRenderingTests: XCTestCase {
  func testPostRendersMetadataSafeMarkdownAndGiscusKey() throws {
    let giscus = GiscusConfiguration(
      repository: "owner/repo", repositoryID: "R_123", category: "Comments", categoryID: "DIC_123")
    let configuration = SiteConfiguration(
      baseURL: "https://owner.github.io", basePath: "/repo", repository: "owner/repo",
      giscus: giscus)
    let post = BlogPost(
      id: "stable-post-id", title: "Swift <script>", slug: "swift-script",
      publishedAt: try XCTUnwrap(BlogDate.parse("2026-01-01")), summary: "Safe & useful",
      tags: ["Swift"],
      isDraft: false, coverImage: nil,
      content: "# Title\n\n`<value>` [Posts](/posts/)\n\n```swift\nlet value = \"<safe>\"\n```",
      sourceFile: "post.md"
    )
    let html = PostDetailView().render(post: post, layout: PageLayout(configuration: configuration))
    XCTAssertTrue(html.contains("Swift &lt;script>"))
    XCTAssertTrue(html.contains("href=\"/repo/posts/\""))
    XCTAssertTrue(html.contains("&lt;value&gt;"))
    XCTAssertTrue(html.contains("data-term=\"stable-post-id\""))
    XCTAssertTrue(
      html.contains("rel=\"canonical\" href=\"https://owner.github.io/repo/posts/swift-script/\""))
  }

  func testMissingGiscusShowsSetupMessage() throws {
    let configuration = SiteConfiguration(baseURL: "https://example.com")
    let post = BlogPost(
      id: "id", title: "Title", slug: "title",
      publishedAt: try XCTUnwrap(BlogDate.parse("2026-01-01")),
      summary: "Summary", tags: [], isDraft: false, coverImage: nil, content: "Body",
      sourceFile: "post.md"
    )
    let html = PostDetailView().render(post: post, layout: PageLayout(configuration: configuration))
    XCTAssertTrue(html.contains("giscus 설정을 마치면"))
    XCTAssertFalse(html.contains("https://giscus.app/client.js"))
  }

  func testMarkdownRejectsExecutableLinks() {
    let html = MarkdownRenderer().render(
      "[unsafe](javascript:alert(1)) and ![image](data:text/html,bad) [remote](//example.com)"
    )
    XCTAssertFalse(html.contains("javascript:"))
    XCTAssertFalse(html.contains("data:text"))
    XCTAssertFalse(html.contains("//example.com"))
    XCTAssertTrue(html.contains("unsafe"))
  }
}
