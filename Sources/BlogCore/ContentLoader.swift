import Foundation
import Markdown

public enum ContentError: Error, LocalizedError, Equatable {
  case directoryNotFound(String)
  case missingFrontMatter(file: String)
  case missingFrontMatterTerminator(file: String)
  case invalidFrontMatterLine(file: String, line: Int, value: String)
  case duplicateField(file: String, field: String)
  case missingField(file: String, field: String)
  case invalidDate(file: String, value: String)
  case invalidSlug(file: String, value: String)
  case invalidIdentifier(file: String, value: String)
  case invalidBoolean(file: String, field: String, value: String)
  case invalidTag(file: String, value: String)
  case emptyBody(file: String)
  case duplicateSlug(String)
  case duplicateIdentifier(String)
  case missingCoverImage(file: String, path: String)
  case invalidCoverImage(file: String, path: String)
  case missingSeriesDefinition(directory: String)
  case seriesSlugMismatch(file: String, slug: String, directory: String)
  case duplicateTopic(series: String, topic: String)
  case invalidTopicStatus(file: String, value: String)
  case incompleteSeriesMembership(file: String)
  case invalidPart(file: String, value: String)
  case unknownSeries(file: String, series: String)
  case unknownTopic(file: String, series: String, topic: String)
  case duplicatePart(series: String, topic: String, part: Int)
  case invalidQuote(line: Int, value: String)

  public var errorDescription: String? {
    switch self {
    case .directoryNotFound(let path):
      "콘텐츠 디렉터리를 찾을 수 없습니다: \(path)"
    case .missingFrontMatter(let file):
      "\(file): front matter가 '---'로 시작해야 합니다."
    case .missingFrontMatterTerminator(let file):
      "\(file): front matter를 닫는 '---'가 없습니다."
    case .invalidFrontMatterLine(let file, let line, let value):
      "\(file):\(line): 올바르지 않은 front matter 항목입니다: \(value)"
    case .duplicateField(let file, let field):
      "\(file): front matter 필드가 중복되었습니다: \(field)"
    case .missingField(let file, let field):
      "\(file): 필수 front matter 필드가 없습니다: \(field)"
    case .invalidDate(let file, let value):
      "\(file): 날짜는 yyyy-MM-dd 형식이어야 합니다: \(value)"
    case .invalidSlug(let file, let value):
      "\(file): slug는 소문자 영문, 숫자와 단일 하이픈만 사용할 수 있습니다: \(value)"
    case .invalidIdentifier(let file, let value):
      "\(file): id는 영문, 숫자, 하이픈과 밑줄만 사용할 수 있습니다: \(value)"
    case .invalidBoolean(let file, let field, let value):
      "\(file): \(field)는 true 또는 false여야 합니다: \(value)"
    case .invalidTag(let file, let value):
      "\(file): 태그에 경로 구분자나 제어 문자를 사용할 수 없습니다: \(value)"
    case .emptyBody(let file):
      "\(file): 글 본문이 비어 있습니다."
    case .duplicateSlug(let slug):
      "중복된 slug입니다: \(slug)"
    case .duplicateIdentifier(let id):
      "중복된 글 id입니다: \(id)"
    case .missingCoverImage(let file, let path):
      "\(file): 대표 이미지 파일을 찾을 수 없습니다: \(path)"
    case .invalidCoverImage(let file, let path):
      "\(file): 대표 이미지는 Public 안의 루트 상대 경로여야 합니다: \(path)"
    case .missingSeriesDefinition(let directory):
      "\(directory): 시리즈 정의 파일 _series.md가 없습니다."
    case .seriesSlugMismatch(let file, let slug, let directory):
      "\(file): 시리즈 slug는 디렉터리 이름과 같아야 합니다: \(slug) ≠ \(directory)"
    case .duplicateTopic(let series, let topic):
      "\(series): 중복된 주제 slug입니다: \(topic)"
    case .invalidTopicStatus(let file, let value):
      "\(file): status는 ongoing 또는 completed여야 합니다: \(value)"
    case .incompleteSeriesMembership(let file):
      "\(file): series, topic, part는 모두 있거나 모두 없어야 합니다."
    case .invalidPart(let file, let value):
      "\(file): part는 1 이상의 정수여야 합니다: \(value)"
    case .unknownSeries(let file, let series):
      "\(file): 존재하지 않는 시리즈입니다: \(series)"
    case .unknownTopic(let file, let series, let topic):
      "\(file): \(series) 시리즈에 없는 주제입니다: \(topic)"
    case .duplicatePart(let series, let topic, let part):
      "\(series)/\(topic): \(part)편이 중복되었습니다."
    case .invalidQuote(let line, let value):
      "quotes.md:\(line): 명언은 '- 문장 — 출처' 형식이어야 합니다: \(value)"
    }
  }
}

public struct ContentLoader: Sendable {
  public init() {}

  public func loadPosts(
    from directory: URL,
    publicDirectory: URL? = nil,
    now: Date = Date(),
    includeDrafts: Bool = false,
    series: [Series] = []
  ) throws -> [BlogPost] {
    var isDirectory: ObjCBool = false
    guard FileManager.default.fileExists(atPath: directory.path, isDirectory: &isDirectory),
      isDirectory.boolValue
    else {
      throw ContentError.directoryNotFound(directory.path)
    }

    let files = try FileManager.default.contentsOfDirectory(
      at: directory,
      includingPropertiesForKeys: nil,
      options: [.skipsHiddenFiles]
    )
    .filter { $0.pathExtension.lowercased() == "md" }
    .sorted { $0.lastPathComponent < $1.lastPathComponent }

    var posts: [BlogPost] = []
    var slugs = Set<String>()
    var identifiers = Set<String>()
    var parts = Set<String>()
    let seriesBySlug = Dictionary(uniqueKeysWithValues: series.map { ($0.slug, $0) })

    for fileURL in files {
      let source = try String(contentsOf: fileURL, encoding: .utf8)
      let post = try parsePost(source, file: fileURL.lastPathComponent)

      guard slugs.insert(post.slug).inserted else {
        throw ContentError.duplicateSlug(post.slug)
      }
      guard identifiers.insert(post.id).inserted else {
        throw ContentError.duplicateIdentifier(post.id)
      }

      if let membership = post.membership {
        guard let owner = seriesBySlug[membership.series] else {
          throw ContentError.unknownSeries(file: post.sourceFile, series: membership.series)
        }
        guard owner.topics.contains(where: { $0.slug == membership.topic }) else {
          throw ContentError.unknownTopic(
            file: post.sourceFile,
            series: membership.series,
            topic: membership.topic
          )
        }
        guard parts.insert("\(membership.series)/\(membership.topic)/\(membership.part)").inserted
        else {
          throw ContentError.duplicatePart(
            series: membership.series,
            topic: membership.topic,
            part: membership.part
          )
        }
      }

      if let coverImage = post.coverImage {
        let components = coverImage.split(separator: "/", omittingEmptySubsequences: false)
        guard
          coverImage.hasPrefix("/"),
          !coverImage.hasPrefix("//"),
          !components.contains(".."),
          !components.contains(".")
        else {
          throw ContentError.invalidCoverImage(file: post.sourceFile, path: coverImage)
        }
      }

      if let coverImage = post.coverImage, let publicDirectory {
        let relativePath = coverImage.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let imageURL = publicDirectory.appendingPathComponent(relativePath)
        guard FileManager.default.fileExists(atPath: imageURL.path) else {
          throw ContentError.missingCoverImage(file: post.sourceFile, path: coverImage)
        }
      }

      if includeDrafts || (!post.isDraft && post.publishedAt <= now) {
        posts.append(post)
      }
    }

    return posts.sorted { lhs, rhs in
      if lhs.publishedAt == rhs.publishedAt { return lhs.slug < rhs.slug }
      return lhs.publishedAt > rhs.publishedAt
    }
  }

  public func parsePost(_ source: String, file: String = "post.md") throws -> BlogPost {
    let frontMatter = try FrontMatter.parse(source, file: file)

    func required(_ key: String) throws -> String {
      guard let value = frontMatter[key], !value.isEmpty else {
        throw ContentError.missingField(file: file, field: key)
      }
      return value
    }

    let id = try required("id")
    guard id.allSatisfy({ $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" }) else {
      throw ContentError.invalidIdentifier(file: file, value: id)
    }

    let slug = try required("slug")
    guard Slug.isValid(slug) else {
      throw ContentError.invalidSlug(file: file, value: slug)
    }

    let dateValue = try required("date")
    guard let publishedAt = BlogDate.parse(dateValue) else {
      throw ContentError.invalidDate(file: file, value: dateValue)
    }

    let draftValue = frontMatter["draft"] ?? "false"
    guard let isDraft = Bool(draftValue) else {
      throw ContentError.invalidBoolean(file: file, field: "draft", value: draftValue)
    }

    let tags = parseTags(frontMatter["tags"] ?? "")
    for tag in tags where !isValidTag(tag) {
      throw ContentError.invalidTag(file: file, value: tag)
    }
    _ = Document(parsing: frontMatter.body)

    let membershipValues = [frontMatter["series"], frontMatter["topic"], frontMatter["part"]]
      .map { $0.flatMap { $0.isEmpty ? nil : $0 } }
    var membership: SeriesMembership?
    if membershipValues.contains(where: { $0 != nil }) {
      guard let series = membershipValues[0], let topic = membershipValues[1],
        let partValue = membershipValues[2]
      else {
        throw ContentError.incompleteSeriesMembership(file: file)
      }
      guard let part = Int(partValue), part >= 1 else {
        throw ContentError.invalidPart(file: file, value: partValue)
      }
      membership = SeriesMembership(series: series, topic: topic, part: part)
    }

    return BlogPost(
      id: id,
      title: try required("title"),
      slug: slug,
      publishedAt: publishedAt,
      summary: try required("summary"),
      tags: tags,
      isDraft: isDraft,
      coverImage: frontMatter["coverImage"].flatMap { $0.isEmpty ? nil : $0 },
      content: frontMatter.body,
      sourceFile: file,
      membership: membership
    )
  }

  private func parseTags(_ value: String) -> [String] {
    let unwrapped: Substring
    if value.hasPrefix("[") && value.hasSuffix("]") {
      unwrapped = value.dropFirst().dropLast()
    } else {
      unwrapped = Substring(value)
    }

    var seen = Set<String>()
    return
      unwrapped
      .split(separator: ",")
      .map { $0.trimmingCharacters(in: .whitespaces).trimmingQuotes() }
      .filter { !$0.isEmpty }
      .filter { seen.insert($0.lowercased()).inserted }
  }

  private func isValidTag(_ tag: String) -> Bool {
    tag != "." && tag != ".." && !tag.contains("/") && !tag.contains("\\")
      && !tag.unicodeScalars.contains(where: CharacterSet.controlCharacters.contains)
  }
}

extension String {
  fileprivate func trimmingQuotes() -> String {
    guard count >= 2 else { return self }
    if (hasPrefix("\"") && hasSuffix("\"")) || (hasPrefix("'") && hasSuffix("'")) {
      return String(dropFirst().dropLast())
    }
    return self
  }
}
