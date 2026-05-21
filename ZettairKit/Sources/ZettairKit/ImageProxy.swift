import Foundation

/// Wikimedia images are reverse-proxied through `/img?url=` to dodge browser-side
/// rate limits and Wikimedia's anti-abuse layer.
///
/// Wikimedia tightened their thumbnail policy in 2026 — requests to /thumb/
/// URLs now frequently 400 with "Use thumbnail sizes listed on …". The
/// originals always work, so we rewrite thumb URLs to their originals before
/// proxying.
public enum ImageProxy {
    public static func url(for raw: String, base: URL = ZettairAPI.defaultBaseURL) -> URL? {
        guard !raw.isEmpty else { return nil }
        let rewritten = rewriteWikimediaThumbToOriginal(raw)
        guard var comps = URLComponents(url: base.appendingPathComponent("/img"), resolvingAgainstBaseURL: false) else {
            return nil
        }
        comps.queryItems = [URLQueryItem(name: "url", value: rewritten)]
        return comps.url
    }

    /// `https://upload.wikimedia.org/wikipedia/commons/thumb/2/28/Foo.jpg/300px-Foo.jpg`
    /// → `https://upload.wikimedia.org/wikipedia/commons/2/28/Foo.jpg`
    ///
    /// Pattern: `/<project>/<lang-or-commons>/thumb/<a>/<ab>/<filename>/<size>px-<filename>(.svg.png?)`
    /// → strip `/thumb` and drop the trailing `/<size>...` segment.
    ///
    /// Non-thumb URLs pass through unchanged.
    static func rewriteWikimediaThumbToOriginal(_ raw: String) -> String {
        guard raw.contains("/thumb/") else { return raw }
        guard var comps = URLComponents(string: raw) else { return raw }
        let parts = comps.path.split(separator: "/", omittingEmptySubsequences: false).map(String.init)
        // Expect: ["", "wikipedia", "<lang>", "thumb", <a>, <ab>, <filename>, <sizeprefix>]
        guard let thumbIdx = parts.firstIndex(of: "thumb"),
              parts.count > thumbIdx + 4 else {
            return raw
        }
        var rebuilt = parts
        rebuilt.remove(at: thumbIdx)                    // drop "thumb"
        rebuilt.removeLast()                            // drop "<NNNpx-...>"
        comps.path = rebuilt.joined(separator: "/")
        return comps.url?.absoluteString ?? raw
    }
}
