import BlogCore
import Foundation
import XCTest

final class QuoteLoaderTests: XCTestCase {
  func testParsesQuotesSkippingCommentsAndBlankLines() throws {
    let quotes = try QuoteLoader().parse(
      """
      # 한 줄에 하나씩: - 문장 — 출처

      - Talk is cheap. Show me the code. — Linus Torvalds
      - Simplicity is prerequisite for reliability. — Edsger W. Dijkstra
      """
    )
    XCTAssertEqual(
      quotes,
      [
        Quote(text: "Talk is cheap. Show me the code.", source: "Linus Torvalds"),
        Quote(text: "Simplicity is prerequisite for reliability.", source: "Edsger W. Dijkstra"),
      ]
    )
  }

  func testSplitsOnLastDash() throws {
    let quotes = try QuoteLoader().parse("- Make it work — then make it right — Kent Beck")
    XCTAssertEqual(quotes, [Quote(text: "Make it work — then make it right", source: "Kent Beck")])
  }

  func testRejectsLineWithoutSource() {
    XCTAssertThrowsError(try QuoteLoader().parse("\n- 출처 없는 문장")) { error in
      XCTAssertEqual(error as? ContentError, .invalidQuote(line: 2, value: "- 출처 없는 문장"))
    }
  }

  func testMissingFileIsEmpty() throws {
    let missing = FileManager.default.temporaryDirectory.appendingPathComponent(
      "\(UUID().uuidString).md"
    )
    XCTAssertEqual(try QuoteLoader().loadQuotes(from: missing), [])
  }
}
