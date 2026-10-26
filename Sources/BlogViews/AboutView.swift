import BlogRouter
import Html

public struct AboutView: Sendable {
  public init() {}

  public func render(layout: PageLayout) -> String {
    let repository = layout.configuration.repository
    let owner = repository.split(separator: "/").first.map(String.init) ?? repository
    let body = element(
      "article",
      [("class", "container page about prose")],
      element("p", [("class", "eyebrow")], .text("ABOUT")),
      element("h1", [], .text("나에 대해서")),
      element(
        "p",
        [("class", "lead")],
        .text("안녕하세요, 강민석이에요. 4년 조금 넘게 iOS 앱을 만들다가, 지금은 다시 대학생으로 돌아와 공부하고 있어요.")
      ),
      element("h2", [], .text("아이폰도 맥북도 없던 고1")),
      element(
        "p",
        [],
        .text(
          "개발을 처음 시작한 건 고등학교 1학년 때였어요. 그때는 아이폰도 맥북도 없었는데, 애플이 만든 생태계가 그냥 멋져 보였어요. 그 관심 하나로 혼자 공부하면서 아이폰 앱을 만들기 시작했고, 그게 4년 넘게 iOS 개발자로 일하는 데까지 이어졌어요."
        )
      ),
      element("h2", [], .text("결국 사용자를 위해")),
      element(
        "p",
        [],
        .text(
          "개발은 결국 그걸 써 줄 사용자를 위해 하는 일이라고 생각해요. 코드를 위해 하는 일이 아니고요. 그렇다고 기능만 돌아가면 코드는 대충 짜도 된다는 뜻은 아니에요. 좋은 경험은 오래 버틸 수 있는 코드 위에서 나오니까, 그 사이에서 적당한 균형을 찾으려고 해요."
        )
      ),
      element(
        "p",
        [],
        .text(
          "AI가 많은 걸 대신해 주는 요즘엔 이 생각이 더 커졌어요. 정보를 찾아 정리해 주기만 하는 앱은 AI로 대체될 수 있겠지만, 사용자의 맥락을 이해하고 기기와 생태계를 잘 살린 앱은 오히려 더 빛날 거라고 믿어요. 앱이 사라지는 게 아니라, 본질 없는 앱이 사라지는 거라고요."
        )
      ),
      element("h2", [], .text("요즘 공부하는 것")),
      element(
        "ul",
        [],
        element(
          "li",
          [],
          element("strong", [], .text("인프라와 서버")),
          .text(" — iOS 밖의 세계가 궁금해져서, 요즘은 인프라와 서버 쪽을 공부하고 있어요.")
        ),
        element(
          "li",
          [],
          element("strong", [], .text("Swift 뜯어보기")),
          .text(
            " — AI 덕분에 코드를 한 줄 한 줄 직접 짜는 일은 많이 줄었어요. 그래서 오히려 Swift와 도구들이 실제로 어떻게 동작하는지, 그 원초적인 부분을 이해하고 제대로 쓰고 싶어졌어요. 그 기록을 "
          ),
          element("a", [("href", layout.router.path(for: .seriesList))], .text("뜯어보기 시리즈")),
          .text("에 남기고 있어요.")
        )
      ),
      element("h2", [], .text("달리는 시간")),
      element(
        "p",
        [],
        .text("취미는 러닝이에요. 뛰는 동안만큼은 이런저런 생각을 덜어내고, 온전히 저한테만 집중할 수 있어서 좋아해요.")
      ),
      element(
        "p",
        [],
        element("a", [("href", "https://github.com/\(owner)")], .text("GitHub ↗")),
        .text(" · "),
        element("a", [("href", "https://github.com/\(repository)")], .text("이 블로그 소스 보기 ↗"))
      )
    )
    return layout.render(
      metadata: PageMetadata(
        title: "소개",
        description: "iOS 개발자 강민석을 소개합니다.",
        route: .about
      ),
      body: body
    )
  }
}
