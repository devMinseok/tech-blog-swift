import BlogRouter
import Foundation
import Markdown

public struct MarkdownRenderer: Sendable {
  private let basePath: String

  public init(basePath: String = "") {
    self.basePath = basePath
  }

  public func render(_ source: String) -> String {
    var walker = SafeHTMLWalker(basePath: basePath)
    walker.visit(Document(parsing: source, options: [.parseBlockDirectives, .parseSymbolLinks]))
    return walker.result
  }
}

private struct SafeHTMLWalker: MarkupWalker {
  var result = ""
  let basePath: String
  var inTableHead = false

  init(basePath: String) {
    self.basePath = basePath
  }

  mutating func visitBlockQuote(_ blockQuote: BlockQuote) {
    result += "<blockquote>"
    descendInto(blockQuote)
    result += "</blockquote>\n"
  }

  mutating func visitCodeBlock(_ codeBlock: CodeBlock) {
    let language = codeBlock.language.map { " class=\"language-\(escapeAttribute($0))\"" } ?? ""
    result += "<pre><code\(language)>\(escapeText(codeBlock.code))</code></pre>\n"
  }

  mutating func visitHeading(_ heading: Heading) {
    let id = headingID(heading.plainText)
    result += "<h\(heading.level) id=\"\(escapeAttribute(id))\">"
    descendInto(heading)
    result += "</h\(heading.level)>\n"
  }

  mutating func visitThematicBreak(_ thematicBreak: ThematicBreak) {
    result += "<hr>\n"
  }

  mutating func visitHTMLBlock(_ html: HTMLBlock) {
    result += "<pre class=\"raw-html\"><code>\(escapeText(html.rawHTML))</code></pre>\n"
  }

  mutating func visitListItem(_ listItem: ListItem) {
    result += "<li>"
    if let checkbox = listItem.checkbox {
      let checked = checkbox == .checked ? " checked" : ""
      result += "<input type=\"checkbox\" disabled\(checked)> "
    }
    descendInto(listItem)
    result += "</li>\n"
  }

  mutating func visitOrderedList(_ orderedList: OrderedList) {
    let start = orderedList.startIndex == 1 ? "" : " start=\"\(orderedList.startIndex)\""
    result += "<ol\(start)>\n"
    descendInto(orderedList)
    result += "</ol>\n"
  }

  mutating func visitUnorderedList(_ unorderedList: UnorderedList) {
    result += "<ul>\n"
    descendInto(unorderedList)
    result += "</ul>\n"
  }

  mutating func visitParagraph(_ paragraph: Paragraph) {
    result += "<p>"
    descendInto(paragraph)
    result += "</p>\n"
  }

  mutating func visitTable(_ table: Table) {
    result += "<div class=\"table-scroll\"><table>\n"
    descendInto(table)
    result += "</table></div>\n"
  }

  mutating func visitTableHead(_ tableHead: Table.Head) {
    inTableHead = true
    result += "<thead><tr>"
    descendInto(tableHead)
    result += "</tr></thead>\n"
    inTableHead = false
  }

  mutating func visitTableBody(_ tableBody: Table.Body) {
    result += "<tbody>"
    descendInto(tableBody)
    result += "</tbody>\n"
  }

  mutating func visitTableRow(_ tableRow: Table.Row) {
    result += "<tr>"
    descendInto(tableRow)
    result += "</tr>\n"
  }

  mutating func visitTableCell(_ tableCell: Table.Cell) {
    let name = inTableHead ? "th" : "td"
    result += "<\(name)>"
    descendInto(tableCell)
    result += "</\(name)>"
  }

  mutating func visitInlineCode(_ inlineCode: InlineCode) {
    result += "<code>\(escapeText(inlineCode.code))</code>"
  }

  mutating func visitEmphasis(_ emphasis: Emphasis) {
    result += "<em>"
    descendInto(emphasis)
    result += "</em>"
  }

  mutating func visitStrong(_ strong: Strong) {
    result += "<strong>"
    descendInto(strong)
    result += "</strong>"
  }

  mutating func visitImage(_ image: Image) {
    guard let source = image.source else { return }
    guard let safeSource = safeURL(source, allowMail: false) else { return }
    let title = image.title.map { " title=\"\(escapeAttribute($0))\"" } ?? ""
    result +=
      "<img src=\"\(escapeAttribute(rewrite(safeSource)))\" alt=\"\(escapeAttribute(image.plainText))\" loading=\"lazy\"\(title)>"
  }

  mutating func visitInlineHTML(_ inlineHTML: InlineHTML) {
    result += escapeText(inlineHTML.rawHTML)
  }

  mutating func visitLineBreak(_ lineBreak: LineBreak) {
    result += "<br>\n"
  }

  mutating func visitSoftBreak(_ softBreak: SoftBreak) {
    result += "\n"
  }

  mutating func visitLink(_ link: Link) {
    guard let destination = link.destination else {
      descendInto(link)
      return
    }
    guard let safeDestination = safeURL(destination, allowMail: true) else {
      descendInto(link)
      return
    }
    let href = rewrite(safeDestination)
    let external = href.hasPrefix("https://") || href.hasPrefix("http://")
    let extra = external ? " rel=\"noopener noreferrer\"" : ""
    result += "<a href=\"\(escapeAttribute(href))\"\(extra)>"
    descendInto(link)
    result += "</a>"
  }

  mutating func visitText(_ text: Text) {
    result += escapeText(text.string)
  }

  mutating func visitStrikethrough(_ strikethrough: Strikethrough) {
    result += "<del>"
    descendInto(strikethrough)
    result += "</del>"
  }

  mutating func visitSymbolLink(_ symbolLink: SymbolLink) {
    result += "<code>\(escapeText(symbolLink.destination ?? symbolLink.plainText))</code>"
  }

  private func rewrite(_ path: String) -> String {
    guard path.hasPrefix("/"), !path.hasPrefix("//"), !basePath.isEmpty else { return path }
    if path == basePath || path.hasPrefix(basePath + "/") { return path }
    return basePath + path
  }

  private func safeURL(_ value: String, allowMail: Bool) -> String? {
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.hasPrefix("//") else { return nil }
    if let scheme = URLComponents(string: trimmed)?.scheme?.lowercased() {
      if scheme == "mailto" { return allowMail ? value : nil }
      guard scheme == "https" || scheme == "http" else { return nil }
    }
    return value
  }

  private func headingID(_ text: String) -> String {
    let lowered = text.lowercased()
    let scalars = lowered.unicodeScalars.map { scalar -> Character in
      if CharacterSet.alphanumerics.contains(scalar) || scalar.value > 127 {
        return Character(String(scalar))
      }
      return "-"
    }
    let value = String(scalars).split(separator: "-", omittingEmptySubsequences: true).joined(
      separator: "-")
    return value.isEmpty ? "section" : value
  }

  private func escapeText(_ value: String) -> String {
    value
      .replacingOccurrences(of: "&", with: "&amp;")
      .replacingOccurrences(of: "<", with: "&lt;")
      .replacingOccurrences(of: ">", with: "&gt;")
  }

  private func escapeAttribute(_ value: String) -> String {
    escapeText(value)
      .replacingOccurrences(of: "\"", with: "&quot;")
      .replacingOccurrences(of: "'", with: "&#39;")
  }
}
