(() => {
  const escapeHTML = (value) => value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;');
  const swiftTokens = /(\/\/.*$|\/\*[\s\S]*?\*\/|"(?:\\.|[^"\\])*"|\b(?:actor|associatedtype|async|await|break|case|catch|class|continue|default|defer|do|else|enum|extension|fallthrough|false|fileprivate|for|func|guard|if|import|in|init|inout|internal|is|let|nil|nonisolated|open|operator|private|protocol|public|repeat|rethrows|return|self|some|static|struct|subscript|super|switch|throw|throws|true|try|typealias|var|where|while)\b|\b\d+(?:\.\d+)?\b)/gm;

  document.querySelectorAll('pre code.language-swift').forEach((node) => {
    const source = node.textContent || '';
    let cursor = 0;
    let html = '';
    for (const match of source.matchAll(swiftTokens)) {
      html += escapeHTML(source.slice(cursor, match.index));
      const token = match[0];
      const className = token.startsWith('//') || token.startsWith('/*')
        ? 'syntax-comment'
        : token.startsWith('"')
          ? 'syntax-string'
          : /^\d/.test(token)
            ? 'syntax-number'
            : 'syntax-keyword';
      html += `<span class="${className}">${escapeHTML(token)}</span>`;
      cursor = match.index + token.length;
    }
    html += escapeHTML(source.slice(cursor));
    node.innerHTML = html;
  });
})();
