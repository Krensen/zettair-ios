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

/// The big homepage wordmark + stripe.
struct ZettairHero: View {
    var body: some View {
        VStack(spacing: 14) {
            Text("Zettair")
                .font(.custom("Georgia-Italic", size: 64))
                .foregroundStyle(Color.primary)
                .tracking(-2)
                .accessibilityAddTraits(.isHeader)
            BrandStripeView()
                .frame(width: 280, height: 4)
        }
    }
}

/// The small wordmark + stripe used as a "go home" button at the top of the
/// results view. Mirrors .logo-small / .logo-small-stripe from index.html.
struct ZettairSmallLogo: View {
    var body: some View {
        VStack(spacing: 4) {
            Text("Zettair")
                .font(.custom("Georgia-Italic", size: 22))
                .foregroundStyle(Color.primary)
                .tracking(-0.5)
            BrandStripeView()
                .frame(width: 90, height: 2.5)
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
