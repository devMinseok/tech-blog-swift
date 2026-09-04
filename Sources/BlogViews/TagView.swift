import BlogCore
import BlogRouter
import Html

public struct TagView: Sendable {
  public init() {}

  public func render(tag: String, posts: [BlogPost], layout: PageLayout) -> String {
    let body = element(
      "div",
      [("class", "container page")],
      element(
        "header", [("class", "page-header")], element("p", [("class", "eyebrow")], .text("TAG")),
        element("h1", [], .text(tag)), element("p", [], .text("\(posts.count)개의 글"))),
      element(
        "div", [("class", "post-list")], fragment(posts.map { postCard($0, router: layout.router) })
      )
    )
    return layout.render(
      metadata: PageMetadata(
        title: "#\(tag)", description: "\(tag) 주제로 작성한 기술 글입니다.", route: .tag(tag)),
      body: body
    )
  }
}
