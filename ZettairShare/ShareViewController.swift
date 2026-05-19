import UIKit
import UniformTypeIdentifiers

/// PRD-028 M8 placeholder. Receives selected text or a URL from any app's
/// share sheet, extracts the human-meaningful string, then opens the main
/// app via a zettair:// URL prefilled with the query.
///
/// Full UI (small "Search for ..." confirmation sheet) lands in M8 — this
/// version dismisses immediately and routes to the app, which is the minimal
/// usable behaviour.
final class ShareViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        Task { await handle() }
    }

    private func handle() async {
        let query = await extractQuery()
        if let q = query, !q.isEmpty,
           let encoded = q.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let url = URL(string: "zettair://search?q=\(encoded)") {
            await openURL(url)
        }
        await MainActor.run {
            self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
        }
    }

    private func extractQuery() async -> String? {
        guard let items = extensionContext?.inputItems as? [NSExtensionItem] else { return nil }
        for item in items {
            for provider in (item.attachments ?? []) {
                if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    if let url = try? await provider.loadItem(forTypeIdentifier: UTType.url.identifier) as? URL {
                        return url.lastPathComponent.replacingOccurrences(of: "_", with: " ")
                    }
                }
                if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                    if let text = try? await provider.loadItem(forTypeIdentifier: UTType.plainText.identifier) as? String {
                        return text
                    }
                }
            }
        }
        return nil
    }

    /// Open a URL from an extension. UIApplication.open is unavailable in
    /// extensions; we walk the responder chain looking for one that responds
    /// to `openURL:`. This is a long-standing workaround.
    @discardableResult
    private func openURL(_ url: URL) async -> Bool {
        await MainActor.run {
            var responder: UIResponder? = self
            while let r = responder {
                if let app = r as? UIApplication {
                    app.open(url, options: [:], completionHandler: nil)
                    return true
                }
                if r.responds(to: NSSelectorFromString("openURL:")) {
                    _ = r.perform(NSSelectorFromString("openURL:"), with: url)
                    return true
                }
                responder = r.next
            }
            return false
        }
    }
}
