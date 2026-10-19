import Foundation

public struct SeriesLoader: Sendable {
  public static let definitionFileName = "_series.md"

  public init() {}

  public func loadSeries(from directory: URL) throws -> [Series] {
    guard isDirectory(directory) else { return [] }

    let seriesDirectories = try FileManager.default.contentsOfDirectory(
      at: directory,
      includingPropertiesForKeys: nil,
      options: [.skipsHiddenFiles]
    )
    .filter(isDirectory)
    .sorted { $0.lastPathComponent < $1.lastPathComponent }

    return try seriesDirectories.map(loadSeries(in:))
  }

  private func loadSeries(in directory: URL) throws -> Series {
    let directoryName = directory.lastPathComponent
    let files = try FileManager.default.contentsOfDirectory(
      at: directory,
      includingPropertiesForKeys: nil,
      options: [.skipsHiddenFiles]
    )
    .filter { $0.pathExtension.lowercased() == "md" }
    .sorted { $0.lastPathComponent < $1.lastPathComponent }

    guard let definition = files.first(where: { $0.lastPathComponent == Self.definitionFileName })
    else {
      throw ContentError.missingSeriesDefinition(directory: directoryName)
    }

    let definitionFile = "\(directoryName)/\(Self.definitionFileName)"
    let frontMatter = try FrontMatter.parse(
      String(contentsOf: definition, encoding: .utf8),
      file: definitionFile
    )
    let slug = try validSlug(frontMatter, file: definitionFile)
    guard slug == directoryName else {
      throw ContentError.seriesSlugMismatch(
        file: definitionFile,
        slug: slug,
        directory: directoryName
      )
    }

    var topics: [Topic] = []
    var topicSlugs = Set<String>()
    for file in files where file != definition {
      let topic = try parseTopic(
        String(contentsOf: file, encoding: .utf8),
        file: "\(directoryName)/\(file.lastPathComponent)"
      )
      guard topicSlugs.insert(topic.slug).inserted else {
        throw ContentError.duplicateTopic(series: slug, topic: topic.slug)
      }
      topics.append(topic)
    }

    return Series(
      slug: slug,
      title: try required("title", in: frontMatter, file: definitionFile),
      summary: try required("summary", in: frontMatter, file: definitionFile),
      introduction: frontMatter.body,
      topics: topics.sorted { $0.slug < $1.slug },
      sourceFile: definitionFile
    )
  }

  private func parseTopic(_ source: String, file: String) throws -> Topic {
    let frontMatter = try FrontMatter.parse(source, file: file)
    let slug = try validSlug(frontMatter, file: file)
    let statusValue = frontMatter["status"] ?? TopicStatus.ongoing.rawValue
    guard let status = TopicStatus(rawValue: statusValue) else {
      throw ContentError.invalidTopicStatus(file: file, value: statusValue)
    }
    return Topic(
      slug: slug,
      title: try required("title", in: frontMatter, file: file),
      summary: try required("summary", in: frontMatter, file: file),
      status: status,
      introduction: frontMatter.body,
      sourceFile: file
    )
  }

  private func validSlug(_ frontMatter: FrontMatter, file: String) throws -> String {
    let slug = try required("slug", in: frontMatter, file: file)
    guard Slug.isValid(slug) else {
      throw ContentError.invalidSlug(file: file, value: slug)
    }
    return slug
  }

  private func required(_ key: String, in frontMatter: FrontMatter, file: String) throws -> String {
    guard let value = frontMatter[key], !value.isEmpty else {
      throw ContentError.missingField(file: file, field: key)
    }
    return value
  }

  private func isDirectory(_ url: URL) -> Bool {
    var isDirectory: ObjCBool = false
    return FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
      && isDirectory.boolValue
  }
}
