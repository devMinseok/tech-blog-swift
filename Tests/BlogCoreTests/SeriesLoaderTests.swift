import BlogCore
import Foundation
import XCTest

final class SeriesLoaderTests: XCTestCase {
  private var root: URL!

  override func setUpWithError() throws {
    root = FileManager.default.temporaryDirectory.appendingPathComponent(
      UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
  }

  override func tearDown() {
    try? FileManager.default.removeItem(at: root)
  }

  func testLoadsSeriesAndTopics() throws {
    try write(seriesSource, to: "teardown/_series.md")
    try write(topicSource(status: "completed"), to: "teardown/spm.md")

    let series = try SeriesLoader().loadSeries(from: root)
    XCTAssertEqual(series.map(\.slug), ["teardown"])
    XCTAssertEqual(series[0].title, "뜯어보기")
    XCTAssertEqual(series[0].topics.map(\.slug), ["spm"])
    XCTAssertEqual(series[0].topics[0].status, .completed)
    XCTAssertEqual(series[0].topics[0].sourceFile, "teardown/spm.md")
  }

  func testTopicStatusDefaultsToOngoing() throws {
    try write(seriesSource, to: "teardown/_series.md")
    try write(topicSource(status: nil), to: "teardown/spm.md")

    let series = try SeriesLoader().loadSeries(from: root)
    XCTAssertEqual(series[0].topics[0].status, .ongoing)
  }

  func testMissingSeriesDirectoryIsEmpty() throws {
    let missing = root.appendingPathComponent("Series", isDirectory: true)
    XCTAssertEqual(try SeriesLoader().loadSeries(from: missing), [])
  }

  func testIgnoresTopLevelFiles() throws {
    try write("# Series", to: "README.md")
    XCTAssertEqual(try SeriesLoader().loadSeries(from: root), [])
  }

  func testRejectsMissingSeriesDefinition() throws {
    try write(topicSource(status: nil), to: "teardown/spm.md")
    XCTAssertThrowsError(try SeriesLoader().loadSeries(from: root)) { error in
      XCTAssertEqual(error as? ContentError, .missingSeriesDefinition(directory: "teardown"))
    }
  }

  func testRejectsSlugMismatch() throws {
    try write(
      seriesSource.replacingOccurrences(of: "slug: teardown", with: "slug: other"),
      to: "teardown/_series.md")
    XCTAssertThrowsError(try SeriesLoader().loadSeries(from: root)) { error in
      XCTAssertEqual(
        error as? ContentError,
        .seriesSlugMismatch(file: "teardown/_series.md", slug: "other", directory: "teardown"))
    }
  }

  func testRejectsDuplicateTopic() throws {
    try write(seriesSource, to: "teardown/_series.md")
    try write(topicSource(status: nil), to: "teardown/spm.md")
    try write(topicSource(status: nil), to: "teardown/swiftpm.md")
    XCTAssertThrowsError(try SeriesLoader().loadSeries(from: root)) { error in
      XCTAssertEqual(error as? ContentError, .duplicateTopic(series: "teardown", topic: "spm"))
    }
  }

  func testRejectsInvalidStatus() throws {
    try write(seriesSource, to: "teardown/_series.md")
    try write(topicSource(status: "done"), to: "teardown/spm.md")
    XCTAssertThrowsError(try SeriesLoader().loadSeries(from: root)) { error in
      XCTAssertEqual(
        error as? ContentError, .invalidTopicStatus(file: "teardown/spm.md", value: "done"))
    }
  }

  func testRejectsMissingSummary() throws {
    try write(seriesSource, to: "teardown/_series.md")
    try write(
      topicSource(status: nil).replacingOccurrences(of: "summary: Package.swift부터\n", with: ""),
      to: "teardown/spm.md")
    XCTAssertThrowsError(try SeriesLoader().loadSeries(from: root)) { error in
      XCTAssertEqual(
        error as? ContentError, .missingField(file: "teardown/spm.md", field: "summary"))
    }
  }

  private func write(_ source: String, to relativePath: String) throws {
    let url = root.appendingPathComponent(relativePath)
    try FileManager.default.createDirectory(
      at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    try source.write(to: url, atomically: true, encoding: .utf8)
  }

  private var seriesSource: String {
    """
    ---
    slug: teardown
    title: 뜯어보기
    summary: 원초적인 걸 파봅니다.
    ---

    시리즈 소개
    """
  }

  private func topicSource(status: String?) -> String {
    """
    ---
    slug: spm
    title: SPM 뜯어보기
    summary: Package.swift부터
    \(status.map { "status: \($0)" } ?? "")
    ---

    주제 소개
    """
  }
}
