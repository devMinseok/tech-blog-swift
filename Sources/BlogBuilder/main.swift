import BlogRouter
import BlogSite
import Foundation

#if canImport(Darwin)
  import Darwin
#else
  import Glibc
#endif

@main
enum BlogBuilderCommand {
  static func main() {
    do {
      let options = try Options(arguments: Array(CommandLine.arguments.dropFirst()))
      if options.showHelp {
        print(Options.help)
        return
      }

      let environment = ProcessInfo.processInfo.environment
      let giscus: GiscusConfiguration?
      if let repositoryID = environment["GISCUS_REPO_ID"],
        let categoryID = environment["GISCUS_CATEGORY_ID"],
        !repositoryID.isEmpty,
        !categoryID.isEmpty
      {
        giscus = GiscusConfiguration(
          repository: options.repository,
          repositoryID: repositoryID,
          category: environment["GISCUS_CATEGORY"] ?? "Comments",
          categoryID: categoryID
        )
      } else {
        giscus = nil
      }

      let configuration = SiteConfiguration(
        baseURL: options.baseURL,
        basePath: options.basePath,
        siteName: options.siteName,
        siteDescription: options.siteDescription,
        authorName: options.author,
        repository: options.repository,
        defaultSocialImage: "social-card.png",
        giscus: giscus
      )
      let report = try SiteGenerator(configuration: configuration).generate(
        repositoryRoot: options.repositoryRoot,
        outputDirectory: options.outputDirectory,
        includeDrafts: options.includeDrafts
      )
      print("사이트 생성 완료: \(report.outputDirectory.path)")
      print("글 \(report.postCount)개 · 태그 \(report.tagCount)개 · 페이지 \(report.pageCount)개")
      if giscus == nil {
        print("참고: GISCUS_REPO_ID와 GISCUS_CATEGORY_ID가 없어 댓글 영역은 설정 안내로 표시됩니다.")
      }
    } catch {
      FileHandle.standardError.write(Data("오류: \(error.localizedDescription)\n".utf8))
      exit(EXIT_FAILURE)
    }
  }
}

private struct Options {
  var repositoryRoot: URL
  var outputDirectory: URL
  var baseURL = "https://devminseok.github.io"
  var basePath = "/tech-blog-swift"
  var repository = "devMinseok/tech-blog-swift"
  var siteName = "Minseok.dev"
  var siteDescription = "Swift와 소프트웨어 개발 과정에서 배운 내용을 기록합니다."
  var author = "Minseok"
  var includeDrafts = false
  var showHelp = false

  init(arguments: [String]) throws {
    let current = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
    repositoryRoot = current
    outputDirectory = current.appendingPathComponent(".build/site", isDirectory: true)

    var index = 0
    while index < arguments.count {
      let argument = arguments[index]
      switch argument {
      case "--include-drafts": includeDrafts = true
      case "--help", "-h": showHelp = true
      case "--root", "--output", "--base-url", "--base-path", "--repository", "--site-name",
        "--site-description", "--author":
        guard index + 1 < arguments.count else { throw OptionError.missingValue(argument) }
        index += 1
        let value = arguments[index]
        switch argument {
        case "--root": repositoryRoot = URL(fileURLWithPath: value, isDirectory: true)
        case "--output": outputDirectory = URL(fileURLWithPath: value, isDirectory: true)
        case "--base-url": baseURL = value
        case "--base-path": basePath = value
        case "--repository": repository = value
        case "--site-name": siteName = value
        case "--site-description": siteDescription = value
        case "--author": author = value
        default: break
        }
      default: throw OptionError.unknown(argument)
      }
      index += 1
    }

    if !repositoryRoot.path.hasPrefix("/") {
      repositoryRoot = current.appendingPathComponent(repositoryRoot.path)
    }
    if !outputDirectory.path.hasPrefix("/") {
      outputDirectory = current.appendingPathComponent(outputDirectory.path)
    }
  }

  static let help = """
    사용법: swift run BlogBuilder [옵션]

      --root <경로>              저장소 루트 (기본값: 현재 디렉터리)
      --output <경로>            생성 결과 (기본값: .build/site)
      --base-url <URL>           공개 origin
      --base-path <경로>         GitHub Pages 프로젝트 경로
      --repository <owner/repo>  GitHub 저장소
      --include-drafts           초안과 예약 글 포함
      -h, --help                 도움말

    giscus는 GISCUS_REPO_ID, GISCUS_CATEGORY_ID, GISCUS_CATEGORY 환경 변수로 설정합니다.
    """
}

private enum OptionError: Error, LocalizedError {
  case missingValue(String)
  case unknown(String)

  var errorDescription: String? {
    switch self {
    case .missingValue(let option): "옵션 값이 없습니다: \(option)"
    case .unknown(let option): "알 수 없는 옵션입니다: \(option)"
    }
  }
}
