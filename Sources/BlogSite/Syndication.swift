import BlogCore
import BlogRouter
import Foundation

enum AtomFeed {
  static func render(posts: [BlogPost], configuration: SiteConfiguration) -> String {
    let updated = posts.first.map { atomDate($0.publishedAt) } ?? "1970-01-01T00:00:00Z"
    let entries = posts.map { post in
      let url = configuration.url(for: .post(slug: post.slug))
      return """
          <entry>
            <title>\(xml(post.title))</title>
            <id>\(xml(url))</id>
            <link href="\(xmlAttribute(url))"/>
            <updated>\(atomDate(post.publishedAt))</updated>
            <summary>\(xml(post.summary))</summary>
          </entry>
        """
    }.joined(separator: "\n")

    return """
      <?xml version="1.0" encoding="utf-8"?>
      <feed xmlns="http://www.w3.org/2005/Atom">
        <title>\(xml(configuration.siteName))</title>
        <subtitle>\(xml(configuration.siteDescription))</subtitle>
        <author><name>\(xml(configuration.authorName))</name></author>
        <generator>BlogBuilder</generator>
        <id>\(xml(configuration.url(for: .home)))</id>
        <link href="\(xmlAttribute(configuration.url(for: .home)))"/>
        <link href="\(xmlAttribute(configuration.url(for: .feed)))" rel="self"/>
        <updated>\(updated)</updated>
      \(entries)
      </feed>
      """
  }
}

enum Sitemap {
  static func render(posts: [BlogPost], tags: [String], configuration: SiteConfiguration) -> String
  {
    var routes: [(SiteRoute, Date?)] = [
      (.home, posts.first?.publishedAt), (.posts, posts.first?.publishedAt), (.about, nil),
    ]
    routes += posts.map { (.post(slug: $0.slug), $0.publishedAt) }
    routes += tags.map { tag in
      (
        .tag(tag),
        posts.first { $0.tags.contains { $0.caseInsensitiveCompare(tag) == .orderedSame } }?
          .publishedAt
      )
    }

    let urls = routes.map { route, lastModified in
      let lastmod = lastModified.map { "<lastmod>\(BlogDate.machine($0))</lastmod>" } ?? ""
      return "<url><loc>\(xml(configuration.url(for: route)))</loc>\(lastmod)</url>"
    }.joined(separator: "\n  ")

    return """
      <?xml version="1.0" encoding="UTF-8"?>
      <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
        \(urls)
      </urlset>
      """
  }
}

enum Robots {
  static func render(configuration: SiteConfiguration) -> String {
    """
    User-agent: *
    Allow: /

    Sitemap: \(configuration.url(for: .sitemap))
    """
  }
}

private func atomDate(_ date: Date) -> String {
  let formatter = ISO8601DateFormatter()
  formatter.formatOptions = [.withInternetDateTime]
  return formatter.string(from: date)
}

private func xml(_ value: String) -> String {
  value
    .replacingOccurrences(of: "&", with: "&amp;")
    .replacingOccurrences(of: "<", with: "&lt;")
    .replacingOccurrences(of: ">", with: "&gt;")
}

private func xmlAttribute(_ value: String) -> String {
  xml(value)
    .replacingOccurrences(of: "\"", with: "&quot;")
    .replacingOccurrences(of: "'", with: "&apos;")
}
