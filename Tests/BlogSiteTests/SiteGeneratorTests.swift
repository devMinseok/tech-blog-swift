import BlogCore
import BlogRouter
import BlogSite
import Foundation
import XCTest

final class SiteGeneratorTests: XCTestCase {
  func testGeneratesCompleteProjectPagesSite() throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(
      UUID().uuidString,
      isDirectory: true
    )
    defer { try? FileManager.default.removeItem(at: root) }
    let posts = root.appendingPathComponent("Content/Posts", isDirectory: true)
    let styles = root.appendingPathComponent("Public/styles", isDirectory: true)
    try FileManager.default.createDirectory(at: posts, withIntermediateDirectories: true)
    try FileManager.default.createDirectory(at: styles, withIntermediateDirectories: true)
    try "body{}".write(
      to: styles.appendingPathComponent("site.css"),
      atomically: true,
      encoding: .utf8
    )
    let scripts = root.appendingPathComponent("Public/scripts", isDirectory: true)
    try FileManager.default.createDirectory(at: scripts, withIntermediateDirectories: true)
    try "".write(to: scripts.appendingPathComponent("site.js"), atomically: true, encoding: .utf8)
    try "".write(to: scripts.appendingPathComponent("syntax.js"), atomically: true, encoding: .utf8)
    try "".write(
      to: root.appendingPathComponent("Public/favicon.svg"),
      atomically: true,
      encoding: .utf8
    )
    try "".write(
      to: root.appendingPathComponent("Public/social-card.svg"),
      atomically: true,
      encoding: .utf8
    )
    try postSource.write(
      to: posts.appendingPathComponent("post.md"),
      atomically: true,
      encoding: .utf8
    )

    let output = root.appendingPathComponent("output", isDirectory: true)
    let configuration = SiteConfiguration(
      baseURL: "https://owner.github.io",
      basePath: "/repo",
      repository: "owner/repo",
      defaultSocialImage: "social-card.svg"
    )
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "yyyy-MM-dd"
    let report = try SiteGenerator(configuration: configuration).generate(
      repositoryRoot: root,
      outputDirectory: output,
      now: try XCTUnwrap(formatter.date(from: "2026-09-01"))
    )

    XCTAssertEqual(report.postCount, 1)
    for path in [
      "index.html", "posts/hello-swift/index.html", "tags/Swift/index.html",
      "tags/Swift 동시성/index.html", "feed.xml", "sitemap.xml", "robots.txt", "404.html", ".nojekyll",
      "series/index.html",
    ] {
      XCTAssertTrue(
        FileManager.default.fileExists(atPath: output.appendingPathComponent(path).path),
        path
      )
    }

    let brokenSource = postSource + "\n[Missing page](/missing/)\n"
    try brokenSource.write(
      to: posts.appendingPathComponent("post.md"),
      atomically: true,
      encoding: .utf8
    )
    XCTAssertThrowsError(
      try SiteGenerator(configuration: configuration).generate(
        repositoryRoot: root,
        outputDirectory: root.appendingPathComponent("broken-output"),
        now: try XCTUnwrap(formatter.date(from: "2026-09-01"))
      )
    )
  }

  func testGeneratesSeriesPages() throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(
      UUID().uuidString,
      isDirectory: true
    )
    defer { try? FileManager.default.removeItem(at: root) }
    for asset in ["styles/site.css", "scripts/site.js", "scripts/syntax.js", "favicon.svg"] {
      try write("", to: root, "Public/\(asset)")
    }
    try write(
      postSource.replacingOccurrences(
        of: "draft: false",
        with: "draft: false\nseries: teardown\ntopic: spm\npart: 1"
      ),
      to: root,
      "Content/Posts/post.md"
    )
    try write(
      "---\nslug: teardown\ntitle: 뜯어보기\nsummary: 원초적인 걸 파봅니다.\n---\n\n소개",
      to: root,
      "Content/Series/teardown/_series.md"
    )
    try write(
      "---\nslug: spm\ntitle: SPM 뜯어보기\nsummary: Package.swift부터\n---\n\n소개",
      to: root,
      "Content/Series/teardown/spm.md"
    )

    let output = root.appendingPathComponent("output", isDirectory: true)
    let configuration = SiteConfiguration(
      baseURL: "https://owner.github.io",
      basePath: "/repo",
      repository: "owner/repo"
    )
    try SiteGenerator(configuration: configuration).generate(
      repositoryRoot: root,
      outputDirectory: output,
      now: try XCTUnwrap(BlogDate.parse("2026-09-01"))
    )

    for path in [
      "series/index.html", "series/teardown/index.html", "series/teardown/spm/index.html",
    ] {
      XCTAssertTrue(
        FileManager.default.fileExists(atPath: output.appendingPathComponent(path).path),
        path
      )
    }
    func read(_ path: String) throws -> String {
      try String(contentsOf: output.appendingPathComponent(path), encoding: .utf8)
    }
    XCTAssertTrue(try read("posts/hello-swift/index.html").contains("/repo/series/teardown/spm/"))
    XCTAssertTrue(try read("feed.xml").contains("Hello Swift"))
    XCTAssertTrue(try read("tags/Swift/index.html").contains("Hello Swift"))
    XCTAssertTrue(
      try read("sitemap.xml").contains("https://owner.github.io/repo/series/teardown/spm/")
    )
  }

  private func write(_ value: String, to root: URL, _ relativePath: String) throws {
    let url = root.appendingPathComponent(relativePath)
    try FileManager.default.createDirectory(
      at: url.deletingLastPathComponent(),
      withIntermediateDirectories: true
    )
    try value.write(to: url, atomically: true, encoding: .utf8)
  }

  private var postSource: String {
    """
    ---
    id: post-001
    title: Hello Swift
    slug: hello-swift
    date: 2026-08-01
    summary: Testing generation.
    tags: Swift, Swift 동시성
    draft: false
    ---

    Read [all posts](/posts/) or [go back](../).
    """
  }
}
