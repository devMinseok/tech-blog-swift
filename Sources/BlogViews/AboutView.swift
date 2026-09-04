import BlogRouter
import Html

public struct AboutView: Sendable {
  public init() {}

  public func render(layout: PageLayout) -> String {
    let body = element(
      "article",
      [("class", "container page about prose")],
      element("p", [("class", "eyebrow")], .text("ABOUT")),
      element("h1", [], .text("안녕하세요, Minseok입니다.")),
      element("p", [("class", "lead")], .text("Swift와 소프트웨어 설계를 공부하며 알게 된 내용을 제 언어로 정리합니다.")),
      element("h2", [], .text("이 블로그의 원칙")),
      element(
        "ul", [], element("li", [], .text("직접 확인한 사실과 의견을 구분합니다.")),
        element("li", [], .text("실패 과정과 선택의 이유도 함께 남깁니다.")),
        element("li", [], .text("오래 읽을 수 있도록 단순한 구조를 지향합니다."))),
      element(
        "p", [],
        element(
          "a", [("href", "https://github.com/\(layout.configuration.repository)")],
          .text("GitHub에서 소스 보기 ↗")))
    )
    return layout.render(
      metadata: PageMetadata(title: "소개", description: "블로그와 작성자 소개입니다.", route: .about),
      body: body
    )
  }
}
