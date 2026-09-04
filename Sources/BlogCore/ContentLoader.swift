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
    }
  }
}

public struct ContentLoader: Sendable {
  public init() {}

  public func loadPosts(
    from directory: URL,
    publicDirectory: URL? = nil,
    now: Date = Date(),
    includeDrafts: Bool = false
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

    for fileURL in files {
      let source = try String(contentsOf: fileURL, encoding: .utf8)
      let post = try parsePost(source, file: fileURL.lastPathComponent)

      guard slugs.insert(post.slug).inserted else {
        throw ContentError.duplicateSlug(post.slug)
      }
      guard identifiers.insert(post.id).inserted else {
        throw ContentError.duplicateIdentifier(post.id)
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
      sourceFile: file
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
