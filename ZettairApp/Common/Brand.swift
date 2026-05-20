import SwiftUI

/// Paul Smith-style signature stripe under the Zettair wordmark.
/// Same seven colours as #home .logo-stripe in index.html.
enum BrandStripe {
    static let colors: [Color] = [
        Color(red: 0.910, green: 0.133, blue: 0.165),  // #e8222a red
        Color(red: 0.949, green: 0.396, blue: 0.133),  // #f26522 orange
        Color(red: 0.976, green: 0.659, blue: 0.145),  // #f9a825 yellow
        Color(red: 0.545, green: 0.765, blue: 0.290),  // #8bc34a green
        Color(red: 0.149, green: 0.776, blue: 0.855),  // #26c6da cyan
        Color(red: 0.082, green: 0.396, blue: 0.753),  // #1565c0 blue
        Color(red: 0.416, green: 0.106, blue: 0.604),  // #6a1b9a purple
    ]
}

/// Shared geometry ids so matchedGeometryEffect can morph the big home logo
/// into the small nav-bar logo and back.
private enum LogoGeoID {
    static let wordmark = "zettair.logo.wordmark"
    static let stripe   = "zettair.logo.stripe"
}

/// The big homepage wordmark + stripe.
struct ZettairHero: View {
    let namespace: Namespace.ID

    var body: some View {
        VStack(spacing: 14) {
            Text("Zettair")
                .font(.custom("Georgia-Italic", size: 64))
                .foregroundStyle(Color.primary)
                .tracking(-2)
                .matchedGeometryEffect(id: LogoGeoID.wordmark, in: namespace)
                .accessibilityAddTraits(.isHeader)
            BrandStripeView()
                .frame(width: 280, height: 4)
                .matchedGeometryEffect(id: LogoGeoID.stripe, in: namespace)
        }
    }
}

/// The small wordmark + stripe used as a "back to home" button at the top of
/// the results view. Mirrors .logo-small / .logo-small-stripe from index.html.
struct ZettairSmallLogo: View {
    let namespace: Namespace.ID

    var body: some View {
        VStack(spacing: 3) {
            Text("Zettair")
                .font(.custom("Georgia-Italic", size: 19))
                .foregroundStyle(Color.primary)
                .tracking(-0.5)
                .matchedGeometryEffect(id: LogoGeoID.wordmark, in: namespace)
            BrandStripeView()
                .frame(width: 78, height: 2.5)
                .matchedGeometryEffect(id: LogoGeoID.stripe, in: namespace)
        }
    }
}

struct BrandStripeView: View {
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(BrandStripe.colors.enumerated()), id: \.offset) { _, c in
                Rectangle().fill(c)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
    }
}
