import BlogRouter
import Foundation

struct LinkValidator {
  let configuration: SiteConfiguration

  func brokenLinks(in root: URL) throws -> [String] {
    let rootPath = root.standardizedFileURL.path
    let enumerator = FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil)
    var failures: [String] = []
    while let file = enumerator?.nextObject() as? URL {
      guard file.pathExtension.lowercased() == "html" else { continue }
      let html = try String(contentsOf: file, encoding: .utf8)
      for reference in references(in: html) {
        let raw = referenceBeforeQuery(reference)
        guard !raw.isEmpty, !raw.hasPrefix("//"), !hasScheme(raw) else { continue }

        let destination: URL
        if raw.hasPrefix("/") {
          if !configuration.basePath.isEmpty,
            raw != configuration.basePath,
            !raw.hasPrefix(configuration.basePath + "/")
          {
            failures.append(
              "\(relativeDescription(file, root: root)): basePath 밖의 링크 \(reference)"
            )
            continue
          }

          var localPath = raw
          if !configuration.basePath.isEmpty {
            localPath.removeFirst(configuration.basePath.count)
          }
          let decoded = localPath.removingPercentEncoding ?? localPath
          destination = root.appendingPathComponent(
            decoded.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
          )
        } else {
          let decoded = raw.removingPercentEncoding ?? raw
          destination = file.deletingLastPathComponent().appendingPathComponent(decoded)
        }

        var resolved = destination.standardizedFileURL
        guard resolved.path == rootPath || resolved.path.hasPrefix(rootPath + "/") else {
          failures.append("\(relativeDescription(file, root: root)): 출력 밖의 링크 \(reference)")
          continue
        }

        if raw.hasSuffix("/") || resolved.path == rootPath {
          resolved.appendPathComponent("index.html")
        } else {
          var isDirectory: ObjCBool = false
          if FileManager.default.fileExists(atPath: resolved.path, isDirectory: &isDirectory),
            isDirectory.boolValue
          {
            resolved.appendPathComponent("index.html")
          }
        }
        if !FileManager.default.fileExists(atPath: resolved.path) {
          failures.append("\(relativeDescription(file, root: root)): \(reference)")
        }
      }
    }
    return failures.sorted()
  }

  private func references(in html: String) -> [String] {
    let pattern = #"(?:href|src)=\"([^\"]+)\""#
    guard let expression = try? NSRegularExpression(pattern: pattern) else { return [] }
    let range = NSRange(html.startIndex..., in: html)
    return expression.matches(in: html, range: range).compactMap { match in
      guard let valueRange = Range(match.range(at: 1), in: html) else { return nil }
      return String(html[valueRange])
    }
  }

  private func hasScheme(_ reference: String) -> Bool {
    URLComponents(string: reference)?.scheme != nil
  }

  private func relativeDescription(_ file: URL, root: URL) -> String {
    file.standardizedFileURL.path.replacingOccurrences(
      of: root.standardizedFileURL.path + "/", with: "")
  }

  private func referenceBeforeQuery(_ reference: String) -> String {
    guard let separator = reference.firstIndex(where: { $0 == "?" || $0 == "#" }) else {
      return reference
    }
    return String(reference[..<separator])
  }
}
