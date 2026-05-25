import Foundation

/// Wikimedia images are reverse-proxied through `/img?url=` to dodge browser-side
/// rate limits and Wikimedia's anti-abuse layer.
///
/// Wikimedia's upload.wikimedia.org accepts thumbnails only at a fixed set of
/// "standard" widths. Requests at other widths return
///   400 / 429 "Use thumbnail sizes listed on https://w.wiki/GHai"
/// The server's image_url field happens to encode 300px-, which is NOT on the
/// allowlist — so the proxy returns 404 for almost every result. We fix it
/// here by rewriting the thumb URL to the next-largest allowed width.
///
/// See https://www.mediawiki.org/wiki/Common_thumbnail_sizes
public enum ImageProxy {
    /// Wikimedia's standard thumb widths. Requesting any other size returns a
    /// 429 with "Use thumbnail sizes listed on …" — even via /img.
    public static let allowedThumbWidths: [Int] = [
        20, 40, 60, 120, 250, 330, 500, 960, 1280, 1920, 3840,
    ]

    /// 250px is the sweet spot for 56pt (trending tile) / 64pt (result row)
    /// thumbnails at 3× density. 330px would be next.
    public static let defaultThumbWidth: Int = 250

    /// Returns the URL to fetch — by default, the *direct* Wikimedia URL
    /// with the size rewritten to the closest allowed width.
    ///
    /// We *used* to route every image through `zettair.io/img?url=…`, but
    /// that proxy turns out to cache responses in a way that ignores the
    /// requested thumb width: once /img returned 250px for a given file,
    /// every subsequent request for any other width returns the cached
    /// 250px bytes (a server-side bug we can't fix from here, per the
    /// brief). Fetching Wikimedia directly is fine — they serve to bare
    /// User-Agents at single-phone request volumes, and URLSession's
    /// default UA + the per-launch cache in URLCache.shared keeps load
    /// well below their throttling thresholds.
    public static func url(for raw: String,
                            preferredWidth: Int = defaultThumbWidth) -> URL? {
        guard !raw.isEmpty else { return nil }
        let rewritten = rewriteToAllowedThumbWidth(raw, preferredWidth: preferredWidth)
        return URL(string: rewritten)
    }

    /// Returns the proxied URL (`zettair.io/img?url=…`) for callers that
    /// specifically want it. Currently unused — kept available for the day
    /// the proxy cache is fixed.
    public static func proxiedURL(for raw: String,
                                   preferredWidth: Int = defaultThumbWidth,
                                   base: URL = ZettairAPI.defaultBaseURL) -> URL? {
        guard !raw.isEmpty else { return nil }
        let rewritten = rewriteToAllowedThumbWidth(raw, preferredWidth: preferredWidth)
        guard var comps = URLComponents(url: base.appendingPathComponent("/img"), resolvingAgainstBaseURL: false) else {
            return nil
        }
        comps.queryItems = [URLQueryItem(name: "url", value: rewritten)]
        return comps.url
    }

    /// `https://upload.wikimedia.org/wikipedia/commons/thumb/2/28/Foo.jpg/300px-Foo.jpg`
    /// with preferredWidth=250 →
    /// `https://upload.wikimedia.org/wikipedia/commons/thumb/2/28/Foo.jpg/250px-Foo.jpg`
    ///
    /// Behaviour:
    /// - If the URL is already at an allowed width, pass through unchanged.
    /// - If it's at a non-allowed width, pick the smallest allowed width
    ///   that is ≥ preferredWidth.
    /// - If the URL isn't a thumb URL at all, leave it untouched.
    static func rewriteToAllowedThumbWidth(_ raw: String, preferredWidth: Int) -> String {
        guard raw.contains("/thumb/") else { return raw }
        guard var comps = URLComponents(string: raw) else { return raw }

        // Path shape: /wikipedia/<lang>/thumb/<a>/<ab>/<filename>/<NNNpx-...>
        let parts = comps.path.split(separator: "/", omittingEmptySubsequences: false).map(String.init)
        guard let thumbIdx = parts.firstIndex(of: "thumb"),
              parts.count > thumbIdx + 4 else {
            return raw
        }

        let lastIdx = parts.count - 1
        let sizeSegment = parts[lastIdx]                       // e.g. "300px-Foo.jpg"
        let filename = parts[lastIdx - 1]                      // e.g. "Foo.jpg"
        guard let currentWidth = parseLeadingPxWidth(sizeSegment) else {
            return raw
        }
        let chosen = allowedWidth(for: preferredWidth)
        if currentWidth == chosen { return raw }

        // Replace "NNNpx-" prefix. Everything after the first "px-" is the
        // suffix MediaWiki composed (file basename, possibly with .svg.png).
        guard let pxRange = sizeSegment.range(of: "px-") else { return raw }
        let suffix = sizeSegment[pxRange.upperBound...]
        var newParts = parts
        newParts[lastIdx] = "\(chosen)px-\(suffix)"
        // Filename segment unchanged (it's the source basename, not the size).
        _ = filename
        comps.path = newParts.joined(separator: "/")
        return comps.url?.absoluteString ?? raw
    }

    /// Pick the smallest allowed width ≥ preferred. Saturates at the largest
    /// allowed width if preferred exceeds it.
    static func allowedWidth(for preferred: Int) -> Int {
        for w in allowedThumbWidths where w >= preferred { return w }
        return allowedThumbWidths.last ?? preferred
    }

    /// Parse the leading integer of "NNNpx-Foo.jpg".
    private static func parseLeadingPxWidth(_ s: String) -> Int? {
        let digits = s.prefix(while: { $0.isNumber })
        return Int(digits)
    }
}
