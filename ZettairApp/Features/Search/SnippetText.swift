import SwiftUI

/// Server snippets contain `<b>...</b>` to highlight query terms. SwiftUI's
/// AttributedString with HTML parsing is heavy on the main thread; instead we
/// scan once and build an inline-styled Text.
struct SnippetText: View {
    let html: String

    var body: some View {
        text
    }

    private var text: Text {
        var out = Text("")
        var bold = false
        var buf = ""
        var i = html.startIndex

        func flush() {
            if buf.isEmpty { return }
            let chunk = Text(buf)
            out = out + (bold ? chunk.bold() : chunk)
            buf = ""
        }

        while i < html.endIndex {
            if html[i] == "<" {
                if let end = html.range(of: ">", range: i..<html.endIndex) {
                    let tag = html[html.index(after: i)..<end.lowerBound].lowercased()
                    flush()
                    if tag == "b" || tag == "strong" { bold = true }
                    if tag == "/b" || tag == "/strong" { bold = false }
                    i = end.upperBound
                    continue
                }
            }
            buf.append(html[i])
            i = html.index(after: i)
        }
        flush()
        return out
    }
}
