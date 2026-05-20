import SwiftUI

/// Cold-launch animation. Letters of "Zettair" fade-and-rise one by one,
/// then the Paul-Smith stripe sweeps in beneath them. Total duration
/// is ~1.1 s; long enough to feel deliberate, short enough not to annoy.
///
/// Shown as an overlay above RootView when the app first becomes active.
/// onFinished is called once the animation has fully settled.
struct LaunchView: View {
    let onFinished: () -> Void

    private let letters = Array("Zettair")
    private let perLetterDelay: Double = 0.07
    private let perLetterDuration: Double = 0.34
    private let stripeStartDelay: Double = 0.6
    private let stripeDuration: Double = 0.55
    private let settle: Double = 0.25

    @State private var revealed: Int = 0
    @State private var stripeProgress: CGFloat = 0

    var body: some View {
        ZStack {
            // Solid background masks whatever's underneath until the
            // animation completes; matches the iOS launch screen mood.
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 14) {
                wordmark
                stripe
            }
        }
        .onAppear { startAnimation() }
    }

    private var wordmark: some View {
        HStack(spacing: 0) {
            ForEach(Array(letters.enumerated()), id: \.offset) { idx, ch in
                let show = idx < revealed
                Text(String(ch))
                    .font(.custom("Georgia-Italic", size: 64))
                    .foregroundStyle(Color.primary)
                    .tracking(-2)
                    .opacity(show ? 1 : 0)
                    .offset(y: show ? 0 : 18)
                    .animation(
                        .spring(response: perLetterDuration, dampingFraction: 0.78),
                        value: revealed
                    )
            }
        }
    }

    private var stripe: some View {
        // Reveal the stripe left-to-right by trimming a clip mask.
        BrandStripeView()
            .frame(width: 280, height: 4)
            .mask(
                GeometryReader { geo in
                    Rectangle()
                        .frame(width: geo.size.width * stripeProgress, height: geo.size.height)
                }
            )
    }

    private func startAnimation() {
        // Reveal letters in sequence.
        for i in 0..<letters.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * perLetterDelay) {
                revealed = i + 1
            }
        }
        // Sweep the stripe.
        DispatchQueue.main.asyncAfter(deadline: .now() + stripeStartDelay) {
            withAnimation(.easeOut(duration: stripeDuration)) {
                stripeProgress = 1.0
            }
        }
        // Hand off to the app.
        let total = stripeStartDelay + stripeDuration + settle
        DispatchQueue.main.asyncAfter(deadline: .now() + total) {
            onFinished()
        }
    }
}
