import BlogCore
import BlogRouter
import Html

public struct SeriesListView: Sendable {
  public init() {}

  public func render(catalog: SeriesCatalog, layout: PageLayout) -> String {
    let body = element(
      "div",
      [("class", "container page")],
      element(
        "header", [("class", "page-header")],
        element("p", [("class", "eyebrow")], .text("SERIES")), element("h1", [], .text("시리즈")),
        element("p", [], .text("주제를 골라 이어서 읽어보세요."))),
      catalog.entries.isEmpty
        ? element("p", [("class", "empty-state")], .text("아직 공개된 시리즈가 없습니다."))
        : element(
          "div", [("class", "post-grid")],
          fragment(
            catalog.entries.map { entry in
              seriesCard(
                title: entry.series.title,
                summary: entry.series.summary,
                meta: "주제 \(entry.topics.count)개",
                href: layout.router.path(for: .series(entry.series.slug))
              )
            }))
    )
    return layout.render(
      metadata: PageMetadata(
        title: "시리즈", description: layout.configuration.siteDescription, route: .seriesList),
      body: body
    )
  }
}
