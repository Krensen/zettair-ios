import SwiftUI
import SafariServices

/// Native SFSafariViewController bridge. Picked over a custom WKWebView so the
/// user gets reader mode, password autofill, and Safari's privacy posture for
/// free; PRD-028 non-goal: "no in-app browser".
struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let cfg = SFSafariViewController.Configuration()
        cfg.entersReaderIfAvailable = false
        cfg.barCollapsingEnabled = true
        let vc = SFSafariViewController(url: url, configuration: cfg)
        vc.dismissButtonStyle = .done
        return vc
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
