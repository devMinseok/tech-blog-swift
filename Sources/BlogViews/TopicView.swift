import BlogCore
import BlogRouter
import Html

public struct TopicView: Sendable {
  public init() {}

  public func render(series: SeriesEntry, topic: TopicEntry, layout: PageLayout) -> String {
    let router = layout.router
    let introduction = MarkdownRenderer(basePath: layout.configuration.basePath)
      .render(topic.topic.introduction)
    let body = element(
      "div",
      [("class", "container page")],
      element(
        "header",
        [("class", "page-header")],
        element(
          "p",
          [("class", "eyebrow")],
          element(
            "a",
            [("href", router.path(for: .series(series.series.slug)))],
            .text(series.series.title)
          ),
          .text(" › \(topic.topic.status.label)")
        ),
        element("h1", [], .text(topic.topic.title)),
        element("p", [], .text(topic.topic.summary))
      ),
      element("div", [("class", "prose series-intro")], .raw(introduction)),
      element(
        "ol",
        [("class", "part-list")],
        fragment(
          topic.parts.map { post in
            element(
              "li",
              [("class", "post-card")],
              element(
                "div",
                [("class", "post-card__meta")],
                .text("\(post.membership?.part ?? 0)편 · "),
                element(
                  "time",
                  [("datetime", BlogDate.machine(post.publishedAt))],
                  .text(BlogDate.display(post.publishedAt))
                )
              ),
              element(
                "h2",
                [("class", "post-card__title")],
                element("a", [("href", router.path(for: .post(slug: post.slug)))], .text(post.title))
              ),
              element("p", [("class", "post-card__summary")], .text(post.summary))
            )
          }
        )
      )
    )
    return layout.render(
      metadata: PageMetadata(
        title: topic.topic.title,
        description: topic.topic.summary,
        route: .topic(series: series.series.slug, topic: topic.topic.slug)
      ),
      body: body
    )
  }
}
