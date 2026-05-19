import UIKit

enum Haptics {
    /// Light tap for chips, suggestions, result rows. Cheap to fire often.
    static func tap() {
        let g = UIImpactFeedbackGenerator(style: .light)
        g.impactOccurred()
    }

    /// Success buzz for copy / save / cite.
    static func success() {
        let g = UINotificationFeedbackGenerator()
        g.notificationOccurred(.success)
    }
}
