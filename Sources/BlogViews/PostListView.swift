import BlogCore
import BlogRouter
import Html

public struct PostListView: Sendable {
  public init() {}

  public func render(posts: [BlogPost], layout: PageLayout) -> String {
    let body = element(
      "div",
      [("class", "container page")],
      element(
        "header", [("class", "page-header")],
        element("p", [("class", "eyebrow")], .text("ARCHIVE")), element("h1", [], .text("모든 글")),
        element("p", [], .text("총 \(posts.count)개의 기록"))),
      posts.isEmpty
        ? element("p", [("class", "empty-state")], .text("아직 발행된 글이 없습니다."))
        : element(
          "div", [("class", "post-list")],
          fragment(posts.map { postCard($0, router: layout.router) }))
    )
    return layout.render(
      metadata: PageMetadata(title: "모든 글", description: "지금까지 작성한 기술 글 모음입니다.", route: .posts),
      body: body
    )
  }
}
