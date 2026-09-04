import BlogCore
import BlogRouter
import Html

public struct PostDetailView: Sendable {
  public init() {}

  public func render(post: BlogPost, layout: PageLayout) -> String {
    let markdown = MarkdownRenderer(basePath: layout.configuration.basePath).render(post.content)
    let body = element(
      "article",
      [("class", "container post")],
      element(
        "header",
        [("class", "post-header")],
        element(
          "div", [("class", "post-meta")],
          element(
            "time", [("datetime", BlogDate.machine(post.publishedAt))],
            .text(BlogDate.display(post.publishedAt))),
          .text(" · \(post.estimatedReadingMinutes)분 읽기")),
        element("h1", [], .text(post.title)),
        element("p", [("class", "post-lede")], .text(post.summary)),
        element(
          "div", [("class", "tag-cloud")],
          fragment(post.tags.map { tagLink($0, router: layout.router) })),
        post.coverImage.map {
          element(
            "img",
            [
              ("class", "post-cover"),
              ("src", layout.configuration.assetPath($0)),
              ("alt", "\(post.title) 대표 이미지"),
            ]
          )
        } ?? fragment([])
      ),
      element("div", [("class", "prose")], .raw(markdown)),
      element(
        "footer",
        [("class", "post-footer")],
        element(
          "a", [("href", layout.configuration.sourceURL(for: post.sourceFile))],
          .text("이 글 수정 제안하기 ↗"))
      ),
      comments(post: post, configuration: layout.configuration)
    )
    return layout.render(
      metadata: PageMetadata(
        title: post.title,
        description: post.summary,
        route: .post(slug: post.slug),
        type: "article",
        publishedAt: post.publishedAt,
        tags: post.tags,
        socialImage: post.coverImage
      ),
      body: body
    )
  }

  private func comments(post: BlogPost, configuration: SiteConfiguration) -> Node {
    guard let giscus = configuration.giscus else {
      return element(
        "section",
        [("class", "comments comments--setup"), ("aria-labelledby", "comments-title")],
        element("h2", [("id", "comments-title")], .text("댓글과 반응")),
        element("p", [], .text("GitHub Discussions의 giscus 설정을 마치면 이 위치에 댓글과 반응이 표시됩니다.")),
        element(
          "a", [("href", "https://github.com/\(configuration.repository)/discussions")],
          .text("Discussions 열기 ↗"))
      )
    }

    return element(
      "section",
      [("class", "comments"), ("aria-labelledby", "comments-title")],
      element("h2", [("id", "comments-title")], .text("댓글과 반응")),
      element(
        "script",
        [
          ("src", "https://giscus.app/client.js"),
          ("data-repo", giscus.repository),
          ("data-repo-id", giscus.repositoryID),
          ("data-category", giscus.category),
          ("data-category-id", giscus.categoryID),
          ("data-mapping", "specific"),
          ("data-term", post.id),
          ("data-strict", "1"),
          ("data-reactions-enabled", "1"),
          ("data-emit-metadata", "0"),
          ("data-input-position", "top"),
          ("data-theme", "preferred_color_scheme"),
          ("data-lang", "ko"),
          ("data-loading", "lazy"),
          ("crossorigin", "anonymous"),
          ("async", ""),
        ]
      )
    )
  }
}
