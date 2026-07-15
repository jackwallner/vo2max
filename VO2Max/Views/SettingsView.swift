import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: GoalSettings
    @EnvironmentObject private var store: StoreService
    @StateObject private var health = HealthKitService.shared
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

            Section("VO2 Max Pro") {
                if store.isPro {
                    Label("Lifetime Pro unlocked", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(Theme.positive)
                } else {
                    Button("View lifetime unlock") { showPaywall = true }
                    Button("Restore purchases") { Task { await store.restore() } }
                }
                #if DEBUG
                Toggle("Local Pro override", isOn: Binding(
                    get: { store.isPro },
                    set: { store.setLocalOverride(isPro: $0) }
                ))
                #endif
            }

            Section("Appearance") {
                Picker("Theme", selection: $settings.appearance) {
                    ForEach(AppAppearance.allCases, id: \.rawValue) { appearance in
                        Text(appearance.label).tag(appearance)
                    }
                }
            }

            Section("About") {
                LabeledContent("Version", value: "1.0.0")
                Link("Privacy Policy", destination: URL(string: "https://jackwallner.github.io/vo2max/privacy-policy.html")!)
                Text("VO2 Max Daily Tracker is for fitness awareness. It does not diagnose, treat, cure, or prevent any condition. Discuss health concerns with a qualified clinician.")
                    .font(.caption)
            }
        }
        .navigationTitle("Settings")
        .sheet(isPresented: $showPaywall) { PaywallView() }
    }
}

private struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: StoreService

    var body: some View {
        NavigationStack {
            VStack(spacing: 22) {
                Spacer()
                Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                    .font(.system(size: 76))
                    .foregroundStyle(Theme.cardioGradient)
                Text("VO2 Max Pro")
                    .font(.largeTitle.bold())
                Text("Unlock advanced trend context and future premium dashboard features with one payment. No subscription.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 14) {
                    Label("Lifetime access", systemImage: "infinity")
                    Label("Advanced trend insights", systemImage: "chart.xyaxis.line")
                    Label("Support independent development", systemImage: "heart.fill")
                }
                .font(.headline)
                Spacer()
                Button {
                    Task {
                        await store.purchaseLifetime()
                        if store.isPro { dismiss() }
                    }
                } label: {
                    Text(store.lifetimePackage.map { "Unlock forever · \($0.storeProduct.localizedPriceString)" } ?? "Lifetime unlock")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(Theme.cardio)
                .disabled(store.isLoading)
                if let error = store.errorMessage {
                    Text(error).font(.caption).foregroundStyle(Theme.negative)
                }
                Button("Restore purchases") { Task { await store.restore() } }
                    .font(.footnote)
                Text("Payment is charged to your Apple Account. This is a one-time, non-consumable purchase.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(24)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
        }
    }
}
