import SwiftUI
@preconcurrency import RevenueCat

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
                LabeledContent("Version", value: Bundle.main.appVersionLabel)
                Link("Privacy Policy", destination: URL(string: "https://jackwallner.github.io/vo2max/privacy-policy.html")!)
                Text("VO2 Max Daily Tracker is for fitness awareness. It does not diagnose, treat, cure, or prevent any condition. Discuss health concerns with a qualified clinician.")
                    .font(.caption)
            }
        }
        .navigationTitle("Settings")
        .sheet(isPresented: $showPaywall) { PaywallView() }
    }
}

struct PaywallView: View {
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
                Text("Unlock advanced trend context and future premium dashboard features.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 14) {
                    Label("Monthly, yearly, or lifetime", systemImage: "calendar.badge.checkmark")
                    Label("Advanced trend insights", systemImage: "chart.xyaxis.line")
                    Label("Support independent development", systemImage: "heart.fill")
                }
                .font(.headline)
                Spacer()
                VStack(spacing: 10) {
                    if store.packages.isEmpty {
                        fallbackPlan("Yearly, 7-day free trial", "$14.99")
                        fallbackPlan("Monthly, 7-day free trial", "$1.99")
                        fallbackPlan("Lifetime", "$29.99")
                    }
                    ForEach(store.packages, id: \.identifier) { package in
                        Button {
                            Task {
                                await store.purchase(package)
                                if store.isPro { dismiss() }
                            }
                        } label: {
                            HStack {
                                Text(planName(package.packageType))
                                Spacer()
                                Text(package.storeProduct.localizedPriceString)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .tint(Theme.cardio)
                        .disabled(store.isLoading)
                    }
                }
                if let error = store.errorMessage {
                    Text(error).font(.caption).foregroundStyle(Theme.negative)
                }
                Button("Restore purchases") { Task { await store.restore() } }
                    .font(.footnote)
                Text("Subscriptions renew automatically unless cancelled at least 24 hours before the current period ends. Payment is charged to your Apple Account. Lifetime is a one-time purchase.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                HStack {
                    Link("Terms", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                    Text("·")
                    Link("Privacy", destination: URL(string: "https://jackwallner.github.io/vo2max/privacy-policy.html")!)
                }
                .font(.caption2)
            }
            .padding(24)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
        }
    }

    private func planName(_ type: PackageType) -> String {
        switch type {
        case .annual: "Yearly, 7-day free trial"
        case .monthly: "Monthly, 7-day free trial"
        case .lifetime: "Lifetime"
        default: "VO2 Max Pro"
        }
    }

    private func fallbackPlan(_ name: String, _ price: String) -> some View {
        HStack {
            Text(name)
            Spacer()
            Text(price)
        }
        .padding(.horizontal, 18)
        .frame(maxWidth: .infinity, minHeight: 50)
        .foregroundStyle(.white)
        .background(Theme.cardio, in: RoundedRectangle(cornerRadius: 12))
    }
}
