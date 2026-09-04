import BlogCore
import BlogRouter
import Html

public typealias HTMLNode = Node

func element(
  _ name: String,
  _ attributes: [(String, String?)] = [],
  _ children: Node...
) -> Node {
  .element(
    name,
    attributes.map { key, value in
      (
        key,
        value.map {
          $0.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
        }
      )
    },
    .fragment(children)
  )
}

func fragment(_ children: [Node]) -> Node {
  .fragment(children)
}

func tagLink(_ tag: String, router: BlogRouter) -> Node {
  element(
    "a",
    [("class", "tag"), ("href", router.path(for: .tag(tag)))],
    .text(tag)
  )
}

func postCard(_ post: BlogPost, router: BlogRouter) -> Node {
  element(
    "article",
    [("class", "post-card")],
    element(
      "div",
      [("class", "post-card__meta")],
      element(
        "time", [("datetime", BlogDate.machine(post.publishedAt))],
        .text(BlogDate.display(post.publishedAt))),
      .text(" · \(post.estimatedReadingMinutes)분")
    ),
    element(
      "h2",
      [("class", "post-card__title")],
      element("a", [("href", router.path(for: .post(slug: post.slug)))], .text(post.title))
    ),
    element("p", [("class", "post-card__summary")], .text(post.summary)),
    fragment(post.tags.map { tagLink($0, router: router) })
  )
}

extension Collection where Element == BlogPost {
  var sortedTags: [(name: String, count: Int)] {
    var counts: [String: Int] = [:]
    for post in self {
      for tag in post.tags { counts[tag, default: 0] += 1 }
    }
    return counts.map { ($0.key, $0.value) }.sorted {
      if $0.count == $1.count {
        return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
      }
      return $0.count > $1.count
    }
  }
}
