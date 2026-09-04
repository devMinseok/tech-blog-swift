import Foundation
import URLRouting

public enum SiteRoute: Equatable, Sendable {
  case home
  case posts
  case post(slug: String)
  case tag(String)
  case about
  case feed
  case sitemap
  case robots
  case notFound
}

private struct SiteRouteParser: Parser {
  var body: some Parser<URLRequestData, SiteRoute> {
    OneOf {
      Route(SiteRoute.home)

      Route(SiteRoute.posts) {
        Path { "posts" }
      }

      Route(SiteRoute.post(slug:)) {
        Path {
          "posts"
          Parse(.string)
        }
      }

      Route(SiteRoute.tag) {
        Path {
          "tags"
          Parse(.string)
        }
      }

      Route(SiteRoute.about) {
        Path { "about" }
      }

      Route(SiteRoute.feed) {
        Path { "feed.xml" }
      }

      Route(SiteRoute.sitemap) {
        Path { "sitemap.xml" }
      }

      Route(SiteRoute.robots) {
        Path { "robots.txt" }
      }

      Route(SiteRoute.notFound) {
        Path { "404.html" }
      }
    }
  }
}

public struct SiteConfiguration: Sendable, Equatable {
  public let baseURL: String
  public let basePath: String
  public let siteName: String
  public let siteDescription: String
  public let authorName: String
  public let repository: String
  public let defaultSocialImage: String?
  public let giscus: GiscusConfiguration?

  public init(
    baseURL: String,
    basePath: String = "",
    siteName: String = "Minseok.dev",
    siteDescription: String = "Swift와 소프트웨어 개발 과정에서 배운 내용을 기록합니다.",
    authorName: String = "Minseok",
    repository: String = "devMinseok/tech-blog-swift",
    defaultSocialImage: String? = nil,
    giscus: GiscusConfiguration? = nil
  ) {
    self.baseURL = baseURL.trimmingTrailingSlash()
    self.basePath = Self.normalizeBasePath(basePath)
    self.siteName = siteName
    self.siteDescription = siteDescription
    self.authorName = authorName
    self.repository = repository
    self.defaultSocialImage = defaultSocialImage
    self.giscus = giscus
  }

  public static let local = SiteConfiguration(baseURL: "http://localhost:8000")
  public static let production = SiteConfiguration(
    baseURL: "https://devminseok.github.io",
    basePath: "/tech-blog-swift"
  )

  public func path(for route: SiteRoute) -> String {
    basePath + route.sitePath
  }

  public func url(for route: SiteRoute) -> String {
    baseURL + path(for: route)
  }

  public func assetPath(_ relativePath: String) -> String {
    let normalized = relativePath.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    return "\(basePath)/\(normalized)"
  }

  public func sourceURL(for sourceFile: String) -> String {
    "https://github.com/\(repository)/edit/main/Content/Posts/\(sourceFile)"
  }

  private static func normalizeBasePath(_ path: String) -> String {
    let trimmed = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    return trimmed.isEmpty ? "" : "/\(trimmed)"
  }
}

public struct GiscusConfiguration: Sendable, Equatable {
  public let repository: String
  public let repositoryID: String
  public let category: String
  public let categoryID: String

  public init(repository: String, repositoryID: String, category: String, categoryID: String) {
    self.repository = repository
    self.repositoryID = repositoryID
    self.category = category
    self.categoryID = categoryID
  }
}

public struct BlogRouter: Sendable {
  public let configuration: SiteConfiguration

  public init(configuration: SiteConfiguration) {
    self.configuration = configuration
  }

  public func path(for route: SiteRoute) -> String {
    configuration.path(for: route)
  }

  public func url(for route: SiteRoute) -> String {
    configuration.url(for: route)
  }

  public func outputPath(for route: SiteRoute) -> String {
    route.outputPath
  }

  public func match(path: String) throws -> SiteRoute {
    var normalized = path
    if !configuration.basePath.isEmpty, normalized.hasPrefix(configuration.basePath) {
      normalized.removeFirst(configuration.basePath.count)
    }
    if normalized.count > 1 && normalized.hasSuffix("/") {
      normalized.removeLast()
    }
    return try SiteRouteParser().match(path: normalized)
  }
}

extension SiteRoute {
  public var sitePath: String {
    switch self {
    case .home: "/"
    case .posts: "/posts/"
    case .post(let slug): "/posts/\(slug)/"
    case .tag(let tag): "/tags/\(tag.urlPathComponent)/"
    case .about: "/about/"
    case .feed: "/feed.xml"
    case .sitemap: "/sitemap.xml"
    case .robots: "/robots.txt"
    case .notFound: "/404.html"
    }
  }

  public var outputPath: String {
    switch self {
    case .home: "index.html"
    case .posts: "posts/index.html"
    case .post(let slug): "posts/\(slug)/index.html"
    case .tag(let tag): "tags/\(tag)/index.html"
    case .about: "about/index.html"
    case .feed: "feed.xml"
    case .sitemap: "sitemap.xml"
    case .robots: "robots.txt"
    case .notFound: "404.html"
    }
  }
}

extension String {
  fileprivate var urlPathComponent: String {
    let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-._~"))
    return addingPercentEncoding(withAllowedCharacters: allowed) ?? self
  }

  fileprivate func trimmingTrailingSlash() -> String {
    var value = self
    while value.count > 1 && value.hasSuffix("/") { value.removeLast() }
    return value
  }
}
