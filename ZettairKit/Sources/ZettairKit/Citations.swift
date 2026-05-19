import Foundation

public struct Citation: Equatable, Sendable, Identifiable {
    public let style: CitationStyle
    public let text: String
    public let monospace: Bool

    public var id: CitationStyle { style }
}

public enum CitationStyle: String, CaseIterable, Sendable {
    case apa     = "APA"
    case mla     = "MLA"
    case chicago = "Chicago"
    case harvard = "Harvard"
    case bibtex  = "BibTeX"
}

/// Ports `buildCitations` from index.html (PRD-024). Same format strings so
/// outputs are byte-identical to the website where possible — citations
/// generated on the app and on the site should be interchangeable.
public enum Citations {
    public static func build(title: String, url: String, now: Date = Date(),
                             locale: Locale = Locale(identifier: "en_US_POSIX")) -> [Citation] {
        let cal = Calendar(identifier: .gregorian)
        let comps = cal.dateComponents([.year, .month, .day], from: now)
        let year = comps.year ?? 2026
        let day  = comps.day  ?? 1
        let monthIdx = (comps.month ?? 1) - 1
        let monthLong = monthLongNames[monthIdx]

        let dateAPA      = formatDate(now, style: .apa,      locale: locale)
        let dateMLA      = formatDate(now, style: .mla,      locale: locale)
        let dateChicago  = formatDate(now, style: .chicago,  locale: locale)
        let dateHarvard  = formatDate(now, style: .harvard,  locale: locale)
        let dateBibTeX   = formatDate(now, style: .bibtex,   locale: locale)

        let bibSlug = url.split(separator: "/").last.map(String.init) ?? title.replacingOccurrences(of: " ", with: "")
        let bibKey = "wiki:\(bibSlug)"

        return [
            Citation(style: .apa,
                     text: "Wikipedia contributors. (\(year), \(monthLong) \(day)). \(title). In Wikipedia, The Free Encyclopedia. Retrieved \(dateAPA), from \(url)",
                     monospace: false),
            Citation(style: .mla,
                     text: "\"\(title).\" Wikipedia, The Free Encyclopedia. Wikimedia Foundation, \(dateMLA). Web. \(dateMLA).",
                     monospace: false),
            Citation(style: .chicago,
                     text: "Wikipedia contributors. \"\(title).\" Wikipedia, The Free Encyclopedia. Last modified \(dateChicago). \(url).",
                     monospace: false),
            Citation(style: .harvard,
                     text: "Wikipedia contributors (\(year)) \(title). Available at: \(url) (Accessed: \(dateHarvard)).",
                     monospace: false),
            Citation(style: .bibtex,
                     text: """
                     @misc{\(bibKey),
                       author       = "Wikipedia contributors",
                       title        = "\(title) --- {Wikipedia}{,} The Free Encyclopedia",
                       year         = "\(year)",
                       url          = "\(url)",
                       note         = "[Online; accessed \(dateBibTeX)]"
                     }
                     """,
                     monospace: true),
        ]
    }

    private static let monthLongNames = [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December",
    ]

    /// Format dates to match the website's citeFormatDate behaviour.
    /// APA: "Month DD, YYYY"  e.g. "May 19, 2026"
    /// MLA: "DD Mon. YYYY"    e.g. "19 May 2026"
    /// Chicago: "Month DD, YYYY"
    /// Harvard: "DD Month YYYY"
    /// BibTeX: "DD Month YYYY"
    private static func formatDate(_ date: Date, style: CitationStyle, locale: Locale) -> String {
        let df = DateFormatter()
        df.locale = locale
        switch style {
        case .apa, .chicago: df.dateFormat = "MMMM d, yyyy"
        case .mla:           df.dateFormat = "d MMM yyyy"
        case .harvard:       df.dateFormat = "d MMMM yyyy"
        case .bibtex:        df.dateFormat = "d MMMM yyyy"
        }
        return df.string(from: date)
    }
}
