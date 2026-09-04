import BlogCore
import Foundation
import XCTest

final class ContentLoaderTests: XCTestCase {
  func testParsesPostAndTags() throws {
    let post = try ContentLoader().parsePost(validPost, file: "post.md")
    XCTAssertEqual(post.id, "post-001")
    XCTAssertEqual(post.slug, "hello-swift")
    XCTAssertEqual(post.tags, ["Swift", "Testing"])
    XCTAssertEqual(post.estimatedReadingMinutes, 1)
    XCTAssertFalse(post.isDraft)
  }

  func testRejectsInvalidSlug() {
    let source = validPost.replacingOccurrences(of: "slug: hello-swift", with: "slug: Hello Swift")
    XCTAssertThrowsError(try ContentLoader().parsePost(source)) { error in
      XCTAssertEqual(error as? ContentError, .invalidSlug(file: "post.md", value: "Hello Swift"))
    }
  }

  func testFiltersDraftAndFuturePosts() throws {
    let root = try temporaryDirectory()
    defer { try? FileManager.default.removeItem(at: root) }
    let future = validPost.replacingOccurrences(of: "id: post-001", with: "id: post-002")
      .replacingOccurrences(of: "slug: hello-swift", with: "slug: future-post")
      .replacingOccurrences(of: "date: 2026-01-01", with: "date: 2030-01-01")
    let draft = validPost.replacingOccurrences(of: "id: post-001", with: "id: post-003")
      .replacingOccurrences(of: "slug: hello-swift", with: "slug: draft-post")
      .replacingOccurrences(of: "draft: false", with: "draft: true")
    try validPost.write(
      to: root.appendingPathComponent("published.md"), atomically: true, encoding: .utf8)
    try future.write(
      to: root.appendingPathComponent("future.md"), atomically: true, encoding: .utf8)
    try draft.write(to: root.appendingPathComponent("draft.md"), atomically: true, encoding: .utf8)

    let now = try XCTUnwrap(BlogDate.parse("2026-09-01"))
    let published = try ContentLoader().loadPosts(from: root, now: now)
    let preview = try ContentLoader().loadPosts(from: root, now: now, includeDrafts: true)
    XCTAssertEqual(published.map(\.slug), ["hello-swift"])
    XCTAssertEqual(preview.count, 3)
  }

  func testRejectsDuplicateIdentifiers() throws {
    let root = try temporaryDirectory()
    defer { try? FileManager.default.removeItem(at: root) }
    try validPost.write(
      to: root.appendingPathComponent("one.md"), atomically: true, encoding: .utf8)
    let duplicate = validPost.replacingOccurrences(
      of: "slug: hello-swift", with: "slug: another-post")
    try duplicate.write(
      to: root.appendingPathComponent("two.md"), atomically: true, encoding: .utf8)
    XCTAssertThrowsError(try ContentLoader().loadPosts(from: root, includeDrafts: true)) { error in
      XCTAssertEqual(error as? ContentError, .duplicateIdentifier("post-001"))
    }
  }

  func testRejectsPathLikeTags() {
    let source = validPost.replacingOccurrences(
      of: "tags: Swift, Testing, swift", with: "tags: Swift, ../secret")
    XCTAssertThrowsError(try ContentLoader().parsePost(source)) { error in
      XCTAssertEqual(error as? ContentError, .invalidTag(file: "post.md", value: "../secret"))
    }
  }

  func testRejectsCoverImageOutsidePublicDirectory() throws {
    let root = try temporaryDirectory()
    defer { try? FileManager.default.removeItem(at: root) }
    let source = validPost.replacingOccurrences(
      of: "draft: false",
      with: "draft: false\ncoverImage: ../secret.png"
    )
    try source.write(to: root.appendingPathComponent("post.md"), atomically: true, encoding: .utf8)
    XCTAssertThrowsError(try ContentLoader().loadPosts(from: root)) { error in
      XCTAssertEqual(
        error as? ContentError,
        .invalidCoverImage(file: "post.md", path: "../secret.png")
      )
    }
  }

  private func temporaryDirectory() throws -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(
      UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
  }

  private var validPost: String {
    """
    ---
    id: post-001
    title: Hello Swift
    slug: hello-swift
    date: 2026-01-01
    summary: A post about Swift.
    tags: Swift, Testing, swift
    draft: false
    ---

    This is the body.
    """
  }
}
