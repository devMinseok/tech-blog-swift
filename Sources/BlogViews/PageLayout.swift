import BlogCore
import BlogRouter
import Foundation
import Html

public struct PageMetadata: Sendable, Equatable {
  public let title: String
  public let description: String
  public let route: SiteRoute
  public let type: String
  public let publishedAt: Date?
  public let tags: [String]
  public let socialImage: String?

  public init(
    title: String,
    description: String,
    route: SiteRoute,
    type: String = "website",
    publishedAt: Date? = nil,
    tags: [String] = [],
    socialImage: String? = nil
  ) {
    self.title = title
    self.description = description
    self.route = route
    self.type = type
    self.publishedAt = publishedAt
    self.tags = tags
    self.socialImage = socialImage
  }
}

public struct PageLayout: Sendable {
  public let configuration: SiteConfiguration
  public let router: BlogRouter

  public init(configuration: SiteConfiguration) {
    self.configuration = configuration
    self.router = BlogRouter(configuration: configuration)
  }

  public func render(metadata: PageMetadata, body: Node) -> String {
    let fullTitle =
      metadata.title == configuration.siteName
      ? metadata.title
      : "\(metadata.title) · \(configuration.siteName)"
    let canonical = router.url(for: metadata.route)
    let image = metadata.socialImage ?? configuration.defaultSocialImage

    var head: [Node] = [
      element("meta", [("charset", "utf-8")]),
      element("meta", [("name", "viewport"), ("content", "width=device-width, initial-scale=1")]),
      element("meta", [("name", "color-scheme"), ("content", "light dark")]),
      element("title", [], .text(fullTitle)),
      element("meta", [("name", "description"), ("content", metadata.description)]),
      element("meta", [("name", "author"), ("content", configuration.authorName)]),
      element("link", [("rel", "canonical"), ("href", canonical)]),
      element(
        "link",
        [
          ("rel", "alternate"), ("type", "application/atom+xml"), ("title", configuration.siteName),
          ("href", router.path(for: .feed)),
        ]),
      element(
        "link",
        [
          ("rel", "icon"), ("href", configuration.assetPath("favicon.svg")),
          ("type", "image/svg+xml"),
        ]),
      element(
        "link", [("rel", "stylesheet"), ("href", configuration.assetPath("styles/site.css"))]),
      element("meta", [("property", "og:site_name"), ("content", configuration.siteName)]),
      element("meta", [("property", "og:locale"), ("content", "ko_KR")]),
      element("meta", [("property", "og:type"), ("content", metadata.type)]),
      element("meta", [("property", "og:title"), ("content", metadata.title)]),
      element("meta", [("property", "og:description"), ("content", metadata.description)]),
      element("meta", [("property", "og:url"), ("content", canonical)]),
      element(
        "meta",
        [("name", "twitter:card"), ("content", image == nil ? "summary" : "summary_large_image")]),
      element("meta", [("name", "twitter:title"), ("content", metadata.title)]),
      element("meta", [("name", "twitter:description"), ("content", metadata.description)]),
      element(
        "script", [],
        .raw(
          "try{const t=localStorage.getItem('theme');if(t)document.documentElement.dataset.theme=t}catch(e){}"
        )),
      element(
        "script", [("type", "application/ld+json")],
        .raw(structuredData(metadata: metadata, canonical: canonical))),
    ]

    if let image {
      let imageURL =
        image.hasPrefix("http") ? image : configuration.baseURL + configuration.assetPath(image)
      head.append(element("meta", [("property", "og:image"), ("content", imageURL)]))
      head.append(element("meta", [("property", "og:image:alt"), ("content", metadata.title)]))
      head.append(element("meta", [("name", "twitter:image"), ("content", imageURL)]))
    }
    if let publishedAt = metadata.publishedAt {
      head.append(
        element(
          "meta",
          [("property", "article:published_time"), ("content", BlogDate.machine(publishedAt))]))
    }
    head.append(
      contentsOf: metadata.tags.map {
        element("meta", [("property", "article:tag"), ("content", $0)])
      })

    let document = Node.document(
      element(
        "html",
        [("lang", "ko")],
        element("head", [], fragment(head)),
        element(
          "body",
          [],
          element("a", [("class", "skip-link"), ("href", "#content")], .text("본문으로 건너뛰기")),
          siteHeader(current: metadata.route),
          element("main", [("id", "content"), ("class", "site-main")], body),
          siteFooter(),
          element("script", [("src", configuration.assetPath("scripts/site.js")), ("defer", "")]),
          element("script", [("src", configuration.assetPath("scripts/syntax.js")), ("defer", "")])
        )
      )
    )
    return Html.render(document)
  }

  private func structuredData(metadata: PageMetadata, canonical: String) -> String {
    var value: [String: Any] = [
      "@context": "https://schema.org",
      "@type": metadata.type == "article" ? "BlogPosting" : "WebPage",
      "author": ["@type": "Person", "name": configuration.authorName],
      "description": metadata.description,
      "headline": metadata.title,
      "inLanguage": "ko-KR",
      "url": canonical,
    ]
    if let publishedAt = metadata.publishedAt {
      value["datePublished"] = BlogDate.machine(publishedAt)
    }
    guard let data = try? JSONSerialization.data(withJSONObject: value, options: [.sortedKeys]),
      let json = String(data: data, encoding: .utf8)
    else { return "{}" }
    return json.replacingOccurrences(of: "</", with: "<\\/")
  }

  private func siteHeader(current: SiteRoute) -> Node {
    func navLink(_ title: String, route: SiteRoute, selected: Bool) -> Node {
      element(
        "a",
        [("href", router.path(for: route)), ("aria-current", selected ? "page" : nil)],
        .text(title)
      )
    }

    let postsSelected: Bool
    switch current {
    case .posts, .post, .tag: postsSelected = true
    default: postsSelected = false
    }

    return element(
      "header",
      [("class", "site-header")],
      element(
        "div",
        [("class", "container header-inner")],
        element(
          "a", [("class", "brand"), ("href", router.path(for: .home))],
          .text(configuration.siteName)),
        element(
          "nav",
          [("aria-label", "주요 메뉴")],
          navLink("글", route: .posts, selected: postsSelected),
          navLink("소개", route: .about, selected: current == .about),
          element(
            "button",
            [
              ("class", "theme-toggle"), ("type", "button"), ("aria-label", "색상 모드 전환"),
              ("data-theme-toggle", ""),
            ],
            .text("◐")
          )
        )
      )
    )
  }

  private func siteFooter() -> Node {
    element(
      "footer",
      [("class", "site-footer")],
      element(
        "div",
        [("class", "container footer-inner")],
        element("p", [], .text("© \(configuration.authorName). Swift로 만들고 GitHub Pages로 배포합니다.")),
        element(
          "div",
          [("class", "footer-links")],
          element("a", [("href", router.path(for: .feed))], .text("RSS")),
          element(
            "a", [("href", "https://github.com/\(configuration.repository)")], .text("GitHub"))
        )
      )
    )
  }
}
