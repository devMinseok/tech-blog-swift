import BlogCore
import BlogRouter
import Html

public struct HomeView: Sendable {
  public init() {}

  public func render(posts: [BlogPost], layout: PageLayout) -> String {
    let recent = Array(posts.prefix(5))
    let body = fragment([
      element(
        "section",
        [("class", "hero container")],
        element("p", [("class", "eyebrow")], .text("SWIFT · ARCHITECTURE · NOTES")),
        element("h1", [], .text("배운 것을 오래 남기는 개발 기록")),
        element("p", [("class", "hero__description")], .text(layout.configuration.siteDescription)),
        element(
          "a", [("class", "button-link"), ("href", layout.router.path(for: .posts))],
          .text("모든 글 보기 →"))
      ),
      element(
        "section",
        [("class", "container section")],
        element(
          "div", [("class", "section-heading")], element("h2", [], .text("최근 글")),
          element("a", [("href", layout.router.path(for: .posts))], .text("전체 보기"))),
        recent.isEmpty
          ? element("p", [("class", "empty-state")], .text("아직 발행된 글이 없습니다."))
          : element(
            "div", [("class", "post-grid")],
            fragment(recent.map { postCard($0, router: layout.router) }))
      ),
      element(
        "section",
        [("class", "container section tag-section")],
        element("h2", [], .text("주제별 탐색")),
        element(
          "div", [("class", "tag-cloud")],
          fragment(
            posts.sortedTags.map { tag, count in
              element(
                "a", [("class", "tag tag--count"), ("href", layout.router.path(for: .tag(tag)))],
                .text("\(tag) \(count)"))
            }))
      ),
    ])
    return layout.render(
      metadata: PageMetadata(
        title: layout.configuration.siteName, description: layout.configuration.siteDescription,
        route: .home),
      body: body
    )
  }
}
