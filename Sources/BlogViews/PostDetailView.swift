import BlogCore
import BlogRouter
import Html

public struct PostDetailView: Sendable {
  public init() {}

  public func render(
    post: BlogPost,
    layout: PageLayout,
    series: PostSeriesContext? = nil
  ) -> String {
    let markdown = MarkdownRenderer(basePath: layout.configuration.basePath).render(post.content)
    let body = element(
      "article",
      [("class", "container post")],
      element(
        "header",
        [("class", "post-header")],
        series.map { seriesTrail($0, router: layout.router) } ?? fragment([]),
        element("h1", [], .text(post.title)),
        element("p", [("class", "post-lede")], .text(post.summary)),
        byline(post: post, author: layout.configuration.authorName),
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
      post.tags.isEmpty
        ? fragment([])
        : element(
          "div",
          [("class", "tag-cloud post-tags")],
          fragment(post.tags.map { tagLink($0, router: layout.router) })
        ),
      series.map { partNavigation($0, router: layout.router) } ?? fragment([]),
      element(
        "footer",
        [("class", "post-footer")],
        element(
          "a",
          [("href", layout.configuration.sourceURL(for: post.sourceFile))],
          .text("이 글 수정 제안하기 ↗")
        )
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

  private func byline(post: BlogPost, author: String) -> Node {
    element(
      "div",
      [("class", "byline")],
      element("span", [("class", "byline__avatar"), ("aria-hidden", "true")], .text(String(author.prefix(1)))),
      element(
        "div",
        [("class", "byline__text")],
        element("span", [("class", "byline__name")], .text(author)),
        element(
          "span",
          [("class", "post-meta")],
          .text("\(post.estimatedReadingMinutes)분 읽기 · "),
          element(
            "time",
            [("datetime", BlogDate.machine(post.publishedAt))],
            .text(BlogDate.display(post.publishedAt))
          )
        )
      )
    )
  }

  private func seriesTrail(_ context: PostSeriesContext, router: BlogRouter) -> Node {
    element(
      "nav",
      [("class", "series-trail"), ("aria-label", "시리즈 위치")],
      element("a", [("href", router.path(for: .series(context.series.slug)))], .text(context.series.title)),
      .text(" › "),
      element(
        "a",
        [("href", router.path(for: .topic(series: context.series.slug, topic: context.topic.slug)))],
        .text(context.topic.title)
      ),
      .text(" · \(context.part)편")
    )
  }

  private func partNavigation(_ context: PostSeriesContext, router: BlogRouter) -> Node {
    guard context.previous != nil || context.next != nil else { return fragment([]) }

    func link(_ post: BlogPost?, label: (Int) -> String, className: String) -> Node {
      guard let post, let part = post.membership?.part else {
        return element("span", [("class", "part-nav__empty")])
      }
      return element(
        "a",
        [("class", "part-nav__link \(className)"), ("href", router.path(for: .post(slug: post.slug)))],
        element("small", [], .text(label(part))),
        element("span", [], .text(post.title))
      )
    }

    return element(
      "nav",
      [("class", "part-nav"), ("aria-label", "이전 편과 다음 편")],
      link(context.previous, label: { "← \($0)편" }, className: "part-nav__link--previous"),
      link(context.next, label: { "\($0)편 →" }, className: "part-nav__link--next")
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
          "a",
          [("href", "https://github.com/\(configuration.repository)/discussions")],
          .text("Discussions 열기 ↗")
        )
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
