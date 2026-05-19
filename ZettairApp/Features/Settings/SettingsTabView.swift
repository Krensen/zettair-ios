import SwiftUI

struct SettingsTabView: View {
    @AppStorage("citation.style") private var citationStyle: String = "APA"
    @AppStorage("spotlight.enabled") private var spotlightEnabled: Bool = true
    @AppStorage("haptics.enabled") private var hapticsEnabled: Bool = true

    var body: some View {
        NavigationStack {
            Form {
                Section("Citation") {
                    Picker("Default style", selection: $citationStyle) {
                        Text("APA").tag("APA")
                        Text("MLA").tag("MLA")
                        Text("Chicago").tag("Chicago")
                        Text("Harvard").tag("Harvard")
                        Text("BibTeX").tag("BibTeX")
                    }
                }
                Section("System integration") {
                    Toggle("Index in Spotlight", isOn: $spotlightEnabled)
                    Toggle("Haptic feedback", isOn: $hapticsEnabled)
                }
                Section("About") {
                    HStack { Text("Version"); Spacer(); Text(versionString).foregroundStyle(.secondary) }
                    Link("Website", destination: URL(string: "https://zettair.io")!)
                    Link("Source code", destination: URL(string: "https://github.com/Krensen/zettair-ios")!)
                }
                Section("Acknowledgements") {
                    Text("Search results sourced from English Wikipedia, licensed CC BY-SA. Tap any result to read the full article on Wikipedia.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
        }
    }

    private var versionString: String {
        let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"
        let b = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
        return "\(v) (\(b))"
    }
}
