import BlogRouter
import XCTest

final class BlogRouterTests: XCTestCase {
  private let configuration = SiteConfiguration(
    baseURL: "https://example.github.io/", basePath: "tech-blog")

  func testProjectPagesPaths() {
    let router = BlogRouter(configuration: configuration)
    XCTAssertEqual(router.path(for: .home), "/tech-blog/")
    XCTAssertEqual(router.path(for: .post(slug: "hello-swift")), "/tech-blog/posts/hello-swift/")
    XCTAssertEqual(
      router.outputPath(for: .post(slug: "hello-swift")), "posts/hello-swift/index.html")
    XCTAssertEqual(router.url(for: .feed), "https://example.github.io/tech-blog/feed.xml")
  }

  func testTagIsPercentEncoded() {
    let router = BlogRouter(configuration: configuration)
    XCTAssertEqual(
      router.path(for: .tag("Swift 동시성")), "/tech-blog/tags/Swift%20%EB%8F%99%EC%8B%9C%EC%84%B1/")
    XCTAssertEqual(router.outputPath(for: .tag("Swift 동시성")), "tags/Swift 동시성/index.html")
  }

  func testMatchesGeneratedPaths() throws {
    let router = BlogRouter(configuration: configuration)
    XCTAssertEqual(
      try router.match(path: "/tech-blog/posts/hello-swift/"), .post(slug: "hello-swift"))
    XCTAssertEqual(try router.match(path: "/tech-blog/about/"), .about)
  }
}
