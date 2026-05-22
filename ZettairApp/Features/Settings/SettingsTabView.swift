import SwiftUI
import UserNotifications

struct SettingsTabView: View {
    @AppStorage("citation.style") private var citationStyle: String = "APA"
    @AppStorage("spotlight.enabled") private var spotlightEnabled: Bool = true
    @AppStorage("haptics.enabled") private var hapticsEnabled: Bool = true

    @AppStorage("brief.enabled") private var briefEnabled: Bool = false
    @AppStorage("brief.hour") private var briefHour: Int = 7
    @AppStorage("brief.minute") private var briefMinute: Int = 0

    @State private var nextFire: Date? = nil
    @State private var notifAuthStatus: UNAuthorizationStatus = .notDetermined
    @State private var showingPrePermission = false

    var body: some View {
        NavigationStack {
            Form {
                briefSection
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
            .task { await refreshNotifState() }
            .sheet(isPresented: $showingPrePermission) {
                PrePermissionSheet(onConfirm: handlePrePermissionConfirm,
                                    onCancel: { briefEnabled = false })
                    .presentationDetents([.medium])
            }
        }
    }

    private var briefSection: some View {
        Section {
            Toggle("Daily brief notification", isOn: $briefEnabled)
                .onChange(of: briefEnabled) { newValue in
                    Task { await handleBriefToggle(newValue) }
                }
            if briefEnabled {
                DatePicker("Time", selection: timeBinding, displayedComponents: .hourAndMinute)
                    .onChange(of: briefHour)   { _ in Task { await rescheduleAndRefresh() } }
                    .onChange(of: briefMinute) { _ in Task { await rescheduleAndRefresh() } }

                if notifAuthStatus == .denied {
                    Label("Notifications disabled in Settings", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                        .font(.footnote)
                    Link("Open Settings", destination: URL(string: UIApplication.openSettingsURLString)!)
                } else if let next = nextFire {
                    HStack {
                        Text("Next").foregroundStyle(.secondary)
                        Spacer()
                        Text(next, format: .dateTime.weekday(.wide).hour().minute())
                            .foregroundStyle(.secondary)
                    }
                    .font(.footnote)
                }
            }
        } header: {
            Text("Daily brief")
        } footer: {
            Text("Three trending stories from Wikipedia, ~90 seconds. One notification per day at the time above. We won't send anything else.")
                .font(.caption)
        }
    }

    private var timeBinding: Binding<Date> {
        Binding(
            get: {
                var comps = DateComponents()
                comps.hour = briefHour
                comps.minute = briefMinute
                return Calendar.current.date(from: comps) ?? Date()
            },
            set: { newDate in
                let comps = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                briefHour = comps.hour ?? briefHour
                briefMinute = comps.minute ?? briefMinute
            }
        )
    }

    private func handleBriefToggle(_ on: Bool) async {
        if on {
            let status = await BriefNotifications.authorizationStatus()
            notifAuthStatus = status
            switch status {
            case .notDetermined:
                showingPrePermission = true   // pre-permission, then ask
            case .authorized, .provisional, .ephemeral:
                await rescheduleAndRefresh()
            case .denied:
                // Toggle stays on but warning shows + deep-link to Settings.
                break
            @unknown default: break
            }
        } else {
            BriefNotifications.cancel()
            nextFire = nil
        }
    }

    private func handlePrePermissionConfirm() async {
        showingPrePermission = false
        var t = DateComponents()
        t.hour = briefHour; t.minute = briefMinute
        let granted = await BriefNotifications.requestAndSchedule(at: t)
        notifAuthStatus = await BriefNotifications.authorizationStatus()
        if granted {
            await refreshNotifState()
        } else {
            briefEnabled = false
        }
    }

    private func rescheduleAndRefresh() async {
        guard briefEnabled else { return }
        var t = DateComponents()
        t.hour = briefHour; t.minute = briefMinute
        await BriefNotifications.schedule(at: t)
        await refreshNotifState()
    }

    private func refreshNotifState() async {
        notifAuthStatus = await BriefNotifications.authorizationStatus()
        nextFire = await BriefNotifications.nextFireDate()
    }

    private var versionString: String {
        let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"
        let b = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
        return "\(v) (\(b))"
    }
}

/// Pre-permission sheet. Sets expectations before triggering the system
/// permission prompt, so users don't reflex-deny.
private struct PrePermissionSheet: View {
    let onConfirm: () async -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "newspaper.fill")
                .font(.system(size: 56))
                .foregroundStyle(.tint)
            Text("One notification per day")
                .font(.title3.weight(.semibold))
            VStack(alignment: .leading, spacing: 8) {
                bulletRow("Three trending Wikipedia stories")
                bulletRow("Around 90 seconds to read")
                bulletRow("Only at the time you chose")
                bulletRow("Nothing else, ever")
            }
            .padding(.horizontal, 32)

            Spacer()

            Button {
                Task { await onConfirm() }
            } label: {
                Text("Sounds good")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal)

            Button(role: .cancel) {
                onCancel()
            } label: {
                Text("Not now")
            }
        }
        .padding(.top, 32)
        .padding(.bottom, 24)
    }

    private func bulletRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.tint)
            Text(text).foregroundStyle(.primary)
            Spacer()
        }
        .font(.subheadline)
    }
}
