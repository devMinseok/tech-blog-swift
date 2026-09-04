import BlogRouter
import Html

public struct NotFoundView: Sendable {
  public init() {}

  public func render(layout: PageLayout) -> String {
    let body = element(
      "section",
      [("class", "container not-found")],
      element("p", [("class", "eyebrow")], .text("404")),
      element("h1", [], .text("페이지를 찾을 수 없습니다.")),
      element("p", [], .text("주소가 바뀌었거나 존재하지 않는 페이지입니다.")),
      element(
        "a", [("class", "button-link"), ("href", layout.router.path(for: .home))], .text("홈으로 돌아가기")
      )
    )
    return layout.render(
      metadata: PageMetadata(
        title: "페이지를 찾을 수 없음", description: "요청한 페이지를 찾을 수 없습니다.", route: .notFound),
      body: body
    )
  }
}
