import BlogCore
import BlogRouter
import BlogViews
import Foundation

public enum SiteGenerationError: Error, LocalizedError {
  case unsafeOutputPath(String)
  case missingPublicDirectory(String)
  case brokenInternalLinks([String])

  public var errorDescription: String? {
    switch self {
    case .unsafeOutputPath(let path):
      "안전하지 않은 출력 경로입니다: \(path)"
    case .missingPublicDirectory(let path):
      "정적 파일 디렉터리를 찾을 수 없습니다: \(path)"
    case .brokenInternalLinks(let links):
      "생성된 사이트에 깨진 내부 링크가 있습니다:\n" + links.joined(separator: "\n")
    }
  }
}

public struct SiteBuildReport: Sendable, Equatable {
  public let postCount: Int
  public let tagCount: Int
  public let pageCount: Int
  public let outputDirectory: URL
}

public struct SiteGenerator: Sendable {
  public let configuration: SiteConfiguration

  public init(configuration: SiteConfiguration) {
    self.configuration = configuration
  }

  @discardableResult
  public func generate(
    repositoryRoot: URL,
    outputDirectory: URL,
    now: Date = Date(),
    includeDrafts: Bool = false
  ) throws -> SiteBuildReport {
    let root = repositoryRoot.standardizedFileURL
    let output = outputDirectory.standardizedFileURL
    try validate(output: output, repositoryRoot: root)

    let contentDirectory = root.appendingPathComponent("Content/Posts", isDirectory: true)
    let publicDirectory = root.appendingPathComponent("Public", isDirectory: true)
    var publicIsDirectory: ObjCBool = false
    guard
      FileManager.default.fileExists(atPath: publicDirectory.path, isDirectory: &publicIsDirectory),
      publicIsDirectory.boolValue
    else {
      throw SiteGenerationError.missingPublicDirectory(publicDirectory.path)
    }

    let posts = try ContentLoader().loadPosts(
      from: contentDirectory,
      publicDirectory: publicDirectory,
      now: now,
      includeDrafts: includeDrafts
    )
    let tags = posts.sortedTagsForSite
    let staging = output.deletingLastPathComponent()
      .appendingPathComponent(".site-staging-\(UUID().uuidString)", isDirectory: true)

    try FileManager.default.createDirectory(at: staging, withIntermediateDirectories: true)
    do {
      try copyPublicDirectory(publicDirectory, to: staging)
      try write("", route: nil, relativePath: ".nojekyll", to: staging)

      let layout = PageLayout(configuration: configuration)
      var pages: [(SiteRoute, String)] = [
        (.home, HomeView().render(posts: posts, layout: layout)),
        (.posts, PostListView().render(posts: posts, layout: layout)),
        (.about, AboutView().render(layout: layout)),
        (.notFound, NotFoundView().render(layout: layout)),
      ]
      pages.append(
        contentsOf: posts.map { post in
          (.post(slug: post.slug), PostDetailView().render(post: post, layout: layout))
        })
      pages.append(
        contentsOf: tags.map { tag in
          let taggedPosts = posts.filter { post in
            post.tags.contains { $0.caseInsensitiveCompare(tag) == .orderedSame }
          }
          return (.tag(tag), TagView().render(tag: tag, posts: taggedPosts, layout: layout))
        })

      for (route, html) in pages {
        try write(html, route: route, relativePath: route.outputPath, to: staging)
      }
      try write(
        AtomFeed.render(posts: posts, configuration: configuration), route: .feed,
        relativePath: SiteRoute.feed.outputPath, to: staging)
      try write(
        Sitemap.render(posts: posts, tags: tags, configuration: configuration), route: .sitemap,
        relativePath: SiteRoute.sitemap.outputPath, to: staging)
      try write(
        Robots.render(configuration: configuration), route: .robots,
        relativePath: SiteRoute.robots.outputPath, to: staging)

      let broken = try LinkValidator(configuration: configuration).brokenLinks(in: staging)
      guard broken.isEmpty else { throw SiteGenerationError.brokenInternalLinks(broken) }

      if FileManager.default.fileExists(atPath: output.path) {
        try FileManager.default.removeItem(at: output)
      }
      try FileManager.default.moveItem(at: staging, to: output)

      return SiteBuildReport(
        postCount: posts.count,
        tagCount: tags.count,
        pageCount: pages.count + 3,
        outputDirectory: output
      )
    } catch {
      try? FileManager.default.removeItem(at: staging)
      throw error
    }
  }

  private func validate(output: URL, repositoryRoot: URL) throws {
    let path = output.standardizedFileURL.path
    let root = repositoryRoot.standardizedFileURL.path
    guard path != "/", path != root,
      path.hasPrefix(root + "/") || path.hasPrefix(NSTemporaryDirectory())
    else {
      throw SiteGenerationError.unsafeOutputPath(path)
    }
  }

  private func copyPublicDirectory(_ source: URL, to destination: URL) throws {
    for item in try FileManager.default.contentsOfDirectory(
      at: source, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
    {
      try FileManager.default.copyItem(
        at: item, to: destination.appendingPathComponent(item.lastPathComponent))
    }
  }

  private func write(_ value: String, route: SiteRoute?, relativePath: String, to root: URL) throws
  {
    let destination = root.appendingPathComponent(relativePath)
    try FileManager.default.createDirectory(
      at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
    try value.write(to: destination, atomically: true, encoding: .utf8)
  }
}

extension Collection where Element == BlogPost {
  fileprivate var sortedTagsForSite: [String] {
    var names: [String: String] = [:]
    for post in self {
      for tag in post.tags { names[tag.lowercased(), default: tag] = tag }
    }
    return names.values.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
  }
}
