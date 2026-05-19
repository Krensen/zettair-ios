import Foundation

/// Wikimedia images are reverse-proxied through `/img?url=` to dodge browser-side
/// rate limits. The iOS client doesn't strictly need the proxy, but using it
/// keeps the User-Agent visible in our own logs and avoids surprises from
/// commons.wikimedia.org changing CORS behaviour.
public enum ImageProxy {
    public static func url(for raw: String, base: URL = ZettairAPI.defaultBaseURL) -> URL? {
        guard !raw.isEmpty else { return nil }
        guard var comps = URLComponents(url: base.appendingPathComponent("/img"), resolvingAgainstBaseURL: false) else {
            return nil
        }
        comps.queryItems = [URLQueryItem(name: "url", value: raw)]
        return comps.url
    }
}
