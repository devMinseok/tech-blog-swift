import BlogCore
import BlogRouter
import Html

public struct HomeView: Sendable {
  public init() {}

  public func render(posts: [BlogPost], layout: PageLayout) -> String {
    let recent = Array(posts.prefix(5))
    let body = fragment([
      hero(),
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

  /// 명언은 `site.js`가 무료 명언 API에서 받아와 채우고, 받아오지 못하면 숨긴 채로 둡니다.
  private func hero() -> Node {
    element(
      "section",
      [("class", "hero container"), ("data-quote", ""), ("hidden", "")],
      element(
        "figure",
        [("class", "hero__quote")],
        element("h1", [("class", "hero__quote-text")]),
        element("figcaption", [("class", "hero__quote-source")], .text("— "), element("cite", []))
      )
    )
  }
}
