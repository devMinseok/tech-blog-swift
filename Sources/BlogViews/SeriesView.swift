import BlogCore
import BlogRouter
import Html

public struct SeriesView: Sendable {
  public init() {}

  public func render(entry: SeriesEntry, layout: PageLayout) -> String {
    let series = entry.series
    let introduction = MarkdownRenderer(basePath: layout.configuration.basePath)
      .render(series.introduction)
    let body = element(
      "div",
      [("class", "container page")],
      element(
        "header",
        [("class", "page-header")],
        element("p", [("class", "eyebrow")], .text("SERIES")),
        element("h1", [], .text(series.title)),
        element("p", [], .text(series.summary))
      ),
      element("div", [("class", "prose series-intro")], .raw(introduction)),
      element(
        "div",
        [("class", "post-grid")],
        fragment(
          entry.topics.map { topic in
            seriesCard(
              title: topic.topic.title,
              summary: topic.topic.summary,
              meta: "\(topic.parts.count)편 · \(topic.topic.status.label)",
              href: layout.router.path(for: .topic(series: series.slug, topic: topic.topic.slug))
            )
          }
        )
      )
    )
    return layout.render(
      metadata: PageMetadata(
        title: series.title,
        description: series.summary,
        route: .series(series.slug)
      ),
      body: body
    )
  }
}
