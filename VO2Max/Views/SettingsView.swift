import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: GoalSettings
    @EnvironmentObject private var store: StoreService
    @StateObject private var health = HealthKitService.shared
    @State private var paywallFocus: PlusFeature?
    @State private var showPaywall = false

    var body: some View {
        Form {
            Section("Target range") {
                Stepper(value: $settings.targetLower, in: 10...89, step: 1) {
                    LabeledContent("Lower", value: settings.targetLower, format: .number.precision(.fractionLength(0)))
                }
                Stepper(value: $settings.targetUpper, in: 11...90, step: 1) {
                    LabeledContent("Upper", value: settings.targetUpper, format: .number.precision(.fractionLength(0)))
                }
                Text("Use a personal fitness target, not a medical threshold.")
                    .font(.caption)
            }

            Section("Fitness age estimate") {
                Stepper("Age: \(settings.chronologicalAge)", value: $settings.chronologicalAge, in: 18...90)
                Picker("Reference curve", selection: $settings.referenceSex) {
                    ForEach(ReferenceSex.allCases, id: \.rawValue) { sex in
                        Text(sex.label).tag(sex)
                    }
                }
                Text("The estimate interpolates broad age and sex reference curves. It is motivational context, not a clinical result.")
                    .font(.caption)
            }

            Section {
                plusToggle("Deep Trends", value: $settings.showDeepTrends, focus: .deepTrends)
                plusToggle("Target outlook", value: $settings.showProjection, focus: .targetProjection)
                plusToggle("Typical-range context", value: $settings.showFitnessBand, focus: .fitnessBand)
                plusToggle("Personal best", value: $settings.showPersonalBest, focus: .personalBest)
                if !store.isPro {
                    Button {
                        paywallFocus = nil
                        showPaywall = true
                    } label: {
                        Label(store.shortConversionCTALabel, systemImage: "sparkles")
                    }
                    Button("Restore purchases") { Task { await store.restore() } }
                }
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
                    Text("Thanks for supporting independent development.")
                } else {
                    Text("VO2+ adds deeper trend context on top of your free dashboard.")
                }
            }

            Section("Apple Health") {
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
        .sheet(isPresented: $showPaywall) { PaywallView(focus: paywallFocus) }
    }

    /// A VO2+ toggle: free users see it locked; flipping it on routes to the
    /// focused paywall instead of persisting.
    private func plusToggle(_ title: String, value: Binding<Bool>, focus: PlusFeature) -> some View {
        Toggle(isOn: Binding(
            get: { store.isPro && value.wrappedValue },
            set: { newValue in
                if store.isPro {
                    value.wrappedValue = newValue
                } else if newValue {
                    paywallFocus = focus
                    showPaywall = true
                }
            }
        )) {
            HStack(spacing: 6) {
                Text(title)
                if !store.isPro {
                    Image(systemName: "lock.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .accessibilityLabel(store.isPro ? title : "\(title) (locked, VO2+ feature)")
    }
}
