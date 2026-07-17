import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: GoalSettings
    @EnvironmentObject private var store: StoreService
    @StateObject private var health = HealthKitService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showPaywall = false

    var body: some View {
        Form {
            Section {
                Button {
                    Task {
                        do { try await health.requestAuthorization() } catch { }
                    }
                } label: {
                    Label("Reconnect Apple Health", systemImage: "heart.fill")
                }
                Button {
                    if let url = URL(string: "x-apple-health://") { UIApplication.shared.open(url) }
                } label: {
                    Label("Open Health", systemImage: "arrow.up.forward.app")
                }
            } header: {
                Text("Apple Health")
            } footer: {
                Text("VO2 max estimates sync automatically from Apple Health. Reconnect if readings stop appearing.")
            }

            Section {
                VStack(spacing: 12) {
                    HStack {
                        Text("Target").font(.subheadline.weight(.medium))
                        Spacer()
                        Text("\(Int(settings.targetLower))–\(Int(settings.targetUpper))")
                            .font(.headline.monospacedDigit())
                            .foregroundStyle(Theme.cardio)
                        Text("mL/kg/min").font(.caption).foregroundStyle(.secondary)
                    }
                    RangeSlider(
                        lowerValue: $settings.targetLower,
                        upperValue: $settings.targetUpper,
                        bounds: 20...70
                    )
                }
                .padding(.vertical, 4)
            } header: {
                Text("Your target range")
            } footer: {
                Text("A personal fitness target, not a medical threshold. Drag the handles to set the band that drives the Today ring and Trends band.")
            }

            Section {
                VStack(spacing: 10) {
                    HStack {
                        Text("Age").font(.subheadline.weight(.medium))
                        Spacer()
                        Text("\(settings.chronologicalAge)")
                            .font(.headline.monospacedDigit())
                            .foregroundStyle(Theme.cardio)
                    }
                    Slider(
                        value: Binding(
                            get: { Double(settings.chronologicalAge) },
                            set: { settings.chronologicalAge = Int($0) }
                        ),
                        in: 18...90,
                        step: 1
                    )
                    .tint(Theme.cardio)
                }
                .padding(.vertical, 4)
                Picker("Reference", selection: $settings.referenceSex) {
                    Text("Female").tag(ReferenceSex.female)
                    Text("Male").tag(ReferenceSex.male)
                    Text("Not set").tag(ReferenceSex.unspecified)
                }
                .pickerStyle(.segmented)
            } header: {
                Text("Profile")
            } footer: {
                Text("Used to estimate your fitness age and typical-range context. Motivational context, not a clinical result.")
            }

            Section {
                if store.isPro {
                    Label("VO2+ active", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(Theme.positive)
                } else {
                    Button {
                        showPaywall = true
                    } label: {
                        Label(store.shortConversionCTALabel, systemImage: "sparkles")
                    }
                }
                Button("Restore purchases") { Task { await store.restore() } }
                #if DEBUG
                Toggle("Local Pro override", isOn: Binding(
                    get: { store.isPro },
                    set: { store.setLocalOverride(isPro: $0) }
                ))
                #endif
            } header: {
                Text("VO2+")
            } footer: {
                if store.isPro {
                    Text("Thanks for supporting independent development. Your insights live in the VO2+ tab.")
                } else {
                    Text("VO2+ adds Deep Trends, target outlook, and personal best in the VO2+ tab.")
                }
            }

            Section("Appearance") {
                Picker("Theme", selection: $settings.appearance) {
                    ForEach(AppAppearance.allCases, id: \.rawValue) { appearance in
                        Text(appearance.label).tag(appearance)
                    }
                }
            }

            Section("About") {
                LabeledContent("Version", value: Bundle.main.appVersionLabel)
                Link("Privacy Policy", destination: URL(string: "https://jackwallner.github.io/vo2max/privacy-policy.html")!)
                Text("VO2 Max Daily Tracker is for fitness awareness. It does not diagnose, treat, cure, or prevent any condition. Discuss health concerns with a qualified clinician.")
                    .font(.caption)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
            }
        }
        .sheet(isPresented: $showPaywall) { PaywallView() }
    }
}
