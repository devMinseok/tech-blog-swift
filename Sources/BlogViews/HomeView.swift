import BlogCore
import BlogRouter
import Foundation
import Html

public struct HomeView: Sendable {
  public init() {}

  public func render(posts: [BlogPost], quotes: [Quote] = [], layout: PageLayout) -> String {
    let recent = Array(posts.prefix(5))
    let body = fragment([
      hero(quotes: quotes),
      element(
        "section",
        [("class", "container section")],
        element(
          "div",
          [("class", "section-heading")],
          element("h2", [], .text("최근 글")),
          element("a", [("href", layout.router.path(for: .posts))], .text("전체 보기"))
        ),
        recent.isEmpty
          ? element("p", [("class", "empty-state")], .text("아직 발행된 글이 없습니다."))
          : element(
            "div",
            [("class", "post-grid")],
            fragment(recent.map { postCard($0, router: layout.router) })
          )
      ),
      element(
        "section",
        [("class", "container section tag-section")],
        element("h2", [], .text("주제별 탐색")),
        element(
          "div",
          [("class", "tag-cloud")],
          fragment(
            posts.sortedTags.map { tag, count in
              element(
                "a",
                [("class", "tag tag--count"), ("href", layout.router.path(for: .tag(tag)))],
                .text("\(tag) \(count)")
              )
            }
          )
        )
      ),
    ])
    return layout.render(
      metadata: PageMetadata(
        title: layout.configuration.siteName,
        description: layout.configuration.siteDescription,
        route: .home
      ),
      body: body
    )
  }

  /// 명언이 있으면 빌드 때 첫 명언을 넣어 두고, 페이지를 열 때마다 인라인 스크립트가 무작위로 바꿉니다.
  private func hero(quotes: [Quote]) -> Node {
    guard let first = quotes.first else {
      return element(
        "section",
        [("class", "hero container")],
        element("h1", [], .text("배운 것을 오래 남기는 개발 기록"))
      )
    }
    return element(
      "section",
      [("class", "hero container")],
      element(
        "figure",
        [("class", "hero__quote"), ("data-quote", "")],
        element("h1", [("class", "hero__quote-text")], .text(first.text)),
        element("figcaption", [("class", "hero__quote-source")], .text("— "), element("cite", [], .text(first.source)))
      ),
      element("script", [("type", "application/json"), ("id", "quotes")], .raw(quotesJSON(quotes))),
      element(
        "script",
        [],
        .raw(
          "(()=>{try{const q=JSON.parse(document.getElementById('quotes').textContent);const p=q[Math.floor(Math.random()*q.length)];const f=document.querySelector('[data-quote]');f.querySelector('h1').textContent=p.text;f.querySelector('cite').textContent=p.source}catch(e){}})()"
        )
      )
    )
  }

  private func quotesJSON(_ quotes: [Quote]) -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    guard let data = try? encoder.encode(quotes), let json = String(data: data, encoding: .utf8) else {
      return "[]"
    }
    return json.replacingOccurrences(of: "</", with: "<\\/")
  }
}
