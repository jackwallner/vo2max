import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: GoalSettings
    @EnvironmentObject private var store: StoreService
    @StateObject private var health = HealthKitService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showPaywall = false

    var body: some View {
        Form {
            healthSection
            targetSection
            profileSection
            plusSection
            appearanceSection
            aboutSection
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

    private var healthSection: some View {
        Section {
            HStack {
                Text("Apple Health status")
                Spacer()
                HStack(spacing: 5) {
                    Image(systemName: health.isAuthorized ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    Text(health.isAuthorized ? "Connected" : "Needs access")
                }
                .foregroundStyle(health.isAuthorized ? Theme.positive : Theme.coral)
            }
            .accessibilityElement(children: .combine)

            Button {
                Task {
                    if health.isAuthorized {
                        await health.refreshCache()
                    } else {
                        try? await health.requestAuthorization()
                    }
                }
            } label: {
                Label(
                    health.isAuthorized ? "Refresh Apple Health" : "Connect Apple Health",
                    systemImage: health.isAuthorized ? "arrow.clockwise" : "heart.fill"
                )
            }

            Button {
                if let url = URL(string: "x-apple-health://") {
                    UIApplication.shared.open(url)
                }
            } label: {
                Label("Open Apple Health", systemImage: "arrow.up.forward.app")
            }

            if let error = health.lastError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(Theme.negative)
            }
        } header: {
            Text("Apple Health")
        } footer: {
            Text("VO2 Max reads cardio fitness estimates from Apple Health, read-only. Refresh if a new estimate is not appearing; use Apple Health to manage source data and permissions.")
        }
    }

    private var targetSection: some View {
        Section {
            VStack(spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Target range")
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    Text("\(Int(settings.targetLower))–\(Int(settings.targetUpper))")
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(Theme.cardio)
                    Text("mL/kg/min")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }

                let typical = CardioFitnessAnalysis.typicalRange(
                    age: settings.chronologicalAge,
                    referenceSex: settings.referenceSex
                )
                Text("Broad typical range for your current profile: \(Int(typical.lowerBound.rounded()))–\(Int(typical.upperBound.rounded())) mL/kg/min")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                RangeSlider(
                    lowerValue: $settings.targetLower,
                    upperValue: $settings.targetUpper,
                    bounds: 20...70,
                    referenceRange: typical
                )
            }
            .padding(.vertical, 4)
        } header: {
            Text("Your target")
        } footer: {
            Text("A personal fitness target, not a medical threshold. It drives the Today ring and target lines in Trends.")
        }
    }

    private var profileSection: some View {
        Section {
            // A menu picker instead of an inline wheel: a 132pt wheel in the
            // middle of a Form swallows vertical drags, so scrolling Settings
            // kept spinning the age instead.
            Picker("Age", selection: $settings.chronologicalAge) {
                ForEach(18...90, id: \.self) { value in
                    Text("\(value)").tag(value)
                }
            }
            .pickerStyle(.menu)
            .tint(Theme.cardio)

            Picker("Reference", selection: $settings.referenceSex) {
                Text("Female").tag(ReferenceSex.female)
                Text("Male").tag(ReferenceSex.male)
                Text("Not set").tag(ReferenceSex.unspecified)
            }
            .pickerStyle(.segmented)
        } header: {
            Text("Reference profile")
        } footer: {
            Text("Used for the broad fitness age estimate and VO2+ typical-range context. These are motivational estimates, not clinical results.")
        }
    }

    private var plusSection: some View {
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

            VStack(alignment: .leading, spacing: 8) {
                plusBenefit("chart.bar.xaxis", "Compare periods", "See matching 30, 90, and 180-day windows.")
                plusBenefit("scope", "Understand direction", "Add target outlook when recent data supports it.")
                plusBenefit("person.2.crop.square.stack", "Add context", "See broad age-reference context and personal bests.")
            }
            .padding(.vertical, 4)

            Button("Restore Purchases") {
                Task { await store.restore() }
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
            Text(store.isPro
                ? "Premium context appears inside Today, Trends, reading details, and the VO2+ hub."
                : "Your latest estimate, basic cardio fitness trend, widgets, and Watch experience remain free.")
        }
    }

    private var appearanceSection: some View {
        Section("Appearance") {
            Picker("Theme", selection: $settings.appearance) {
                ForEach(AppAppearance.allCases, id: \.rawValue) { appearance in
                    Text(appearance.label).tag(appearance)
                }
            }
        }
    }

    private var aboutSection: some View {
        Section("About") {
            LabeledContent("Version", value: Bundle.main.appVersionLabel)
            Link("Privacy Policy", destination: VO2Links.privacyPolicy)
            Link("Terms of Use", destination: VO2Links.standardEULA)
            Text("VO2 Max Daily Tracker is for fitness awareness. Apple Health estimates and broad reference context are not medical measurements. This app does not diagnose, treat, cure, or prevent any condition. Discuss health concerns with a qualified clinician.")
                .font(.caption)
        }
    }

    private func plusBenefit(_ icon: String, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(Theme.cardio)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }
}
