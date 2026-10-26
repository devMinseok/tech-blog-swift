import BlogRouter
import Html

public struct AboutView: Sendable {
  public init() {}

  public func render(layout: PageLayout) -> String {
    let body = element(
      "article",
      [("class", "container page about prose")],
      element("p", [("class", "eyebrow")], .text("ABOUT")),
      element("h1", [], .text("안녕하세요,")),
      element("p", [("class", "lead")], .text("Swift와 소프트웨어 설계를 공부하며 알게 된 내용을 제 언어로 정리합니다.")),
      element("h2", [], .text("앱은 사라질까?")),
      element(
        "p",
        [],
        .text(
          "\"주문해줘, 검색해줘, 예약해줘.\" 말 한마디로 원하는 결과를 얻는 시대가 오면 앱은 더 이상 필요 없어지는 걸까? 굉장히 현실적인 질문이다. 나는 앱이 사라지는 게 아니라, 본질 없는 앱이 사라진다고 생각한다."
        )
      ),
      element(
        "p",
        [],
        .text(
          "비슷한 변화는 이미 겪어봤다. 웹과 모바일 앱이다. 유튜브는 웹에서도 볼 수 있지만, 휴대폰에서는 대부분 유튜브 앱을 쓴다. 상황에 맞는 경험이 있기 때문이다. PC에서는 웹이 편하고 모바일에서는 앱이 편하다. 기술이 발전해도 그 경험의 차이는 사라지지 않았다."
        )
      ),
      element(
        "p",
        [],
        .text(
          "AI 시대도 비슷하게 흘러갈 것 같다. 정보를 찾아 정리해 주기만 하는 앱은 ChatGPT, Claude, Gemini 같은 AI로 대체될 수 있다. 하지만 사용자 경험을 설계하고, 기기 환경을 활용하고, 생태계에 깊이 통합된 앱은 AI와 충분히 공존할 수 있다. 오히려 AI가 흔해질수록 사용자의 맥락을 이해하고 기기의 특성을 살리는 \"진짜 앱\"만 살아남을 것이다."
        )
      ),
      element(
        "p",
        [],
        .text(
          "그래서 앞으로 더 중요해지는 건 생태계와 사용자 경험이다. 애플은 하드웨어, 소프트웨어, 플랫폼을 통해 개발자가 사용자 경험에 집중할 수 있는 환경을 만들어 왔다. AI 시대일수록 그 환경을 얼마나 잘 이해하고 활용해서 의미 있는 경험을 설계하느냐가 앱의 차이를 만든다."
        )
      ),
      element(
        "p",
        [],
        .text(
          "이 블로그에서 AI가 딸깍 한 번에 만들어 주는 것들의 밑바닥을 굳이 파보는 이유도 여기에 있다. 플랫폼이 실제로 어떻게 동작하는지 알아야 그 위에서 대체되기 어려운 경험을 만들 수 있다고 믿는다."
        )
      ),
      element("p", [], element("strong", [], .text("앱은 사라지지 않는다. 더 본질적인 방향으로 가고 있을 뿐이다."))),
      element("h2", [], .text("이 블로그의 원칙")),
      element(
        "ul",
        [],
        element("li", [], .text("직접 확인한 사실과 의견을 구분합니다.")),
        element("li", [], .text("실패 과정과 선택의 이유도 함께 남깁니다.")),
        element("li", [], .text("오래 읽을 수 있도록 단순한 구조를 지향합니다."))
      ),
      element(
        "p",
        [],
        element(
          "a",
          [("href", "https://github.com/\(layout.configuration.repository)")],
          .text("GitHub에서 소스 보기 ↗")
        )
      )
    )
    return layout.render(
      metadata: PageMetadata(title: "소개", description: "블로그와 작성자 소개입니다.", route: .about),
      body: body
    )
  }
}
