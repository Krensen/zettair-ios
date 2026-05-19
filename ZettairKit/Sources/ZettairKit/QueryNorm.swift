import Foundation

/// Mirrors `server.py:query_norm` — lowercase, trim, collapse inner whitespace.
/// Used wherever the client needs to key off the same value as the server
/// (Spotlight indexing, intent donations, summary lookups).
public func queryNorm(_ s: String) -> String {
    let lower = s.lowercased()
    let parts = lower.split(whereSeparator: { $0.isWhitespace })
    return parts.joined(separator: " ")
}
