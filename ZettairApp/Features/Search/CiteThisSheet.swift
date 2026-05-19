import SwiftUI
import ZettairKit
import UIKit

struct CiteThisSheet: View {
    let title: String
    let url: String

    @Environment(\.dismiss) private var dismiss
    @AppStorage("citation.style") private var defaultStyle: String = "APA"
    @State private var copiedStyle: CitationStyle? = nil

    private var citations: [Citation] { Citations.build(title: title, url: url) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(citations) { c in
                        citationRow(c)
                        Divider()
                    }
                    Text("Citations adhere to common style conventions and link to Wikipedia (CC BY-SA).")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                }
                .padding()
            }
            .navigationTitle("Cite this")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    @ViewBuilder
    private func citationRow(_ c: Citation) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(c.style.rawValue)
                    .font(.subheadline.weight(.semibold))
                if c.style.rawValue == defaultStyle {
                    Text("default")
                        .font(.caption2)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.15), in: Capsule())
                        .foregroundStyle(.tint)
                }
                Spacer()
                Button {
                    copy(c)
                } label: {
                    Label(copiedStyle == c.style ? "Copied" : "Copy",
                          systemImage: copiedStyle == c.style ? "checkmark" : "doc.on.doc")
                        .labelStyle(.titleAndIcon)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            Text(c.text)
                .font(c.monospace ? .system(.footnote, design: .monospaced) : .footnote)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func copy(_ c: Citation) {
        UIPasteboard.general.string = c.text
        copiedStyle = c.style
        Haptics.success()
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            if copiedStyle == c.style { copiedStyle = nil }
        }
    }
}
