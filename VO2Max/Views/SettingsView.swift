import SwiftData
import SwiftUI
@preconcurrency import RevenueCat

struct SettingsView: View {
    @EnvironmentObject private var settings: GoalSettings
    @EnvironmentObject private var store: StoreService
    @StateObject private var health = HealthKitService.shared
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \CardioFitnessSample.date, order: .reverse) private var samples: [CardioFitnessSample]

    @State private var showPaywall = false
    @State private var paywallFocus: PlusFeature?
    @State private var showTrialOffer = false
    @State private var trialOfferFocus: PlusFeature?
    @State private var trialOfferDetent: PresentationDetent = .fraction(0.68)
    @State private var trialPurchaseInFlight = false
    @State private var trialPurchaseError: String?
    @State private var reportPreview: ReportPreview?
    @State private var isGeneratingReport = false
    @State private var reportError: String?

    private struct ReportPreview: Identifiable {
        let id = UUID()
        let title: String
        let url: URL
        let shareText: String
    }

    private var points: [CardioFitnessPoint] {
        samples.map { CardioFitnessPoint(date: $0.date, value: $0.value) }
    }

    var body: some View {
        Form {
            healthSection
            targetSection
            profileSection
            plusSection
            appearanceSection
            feedbackSection
            aboutSection
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(focus: paywallFocus)
        }
        .sheet(isPresented: $showTrialOffer, onDismiss: {
            trialPurchaseInFlight = false
            trialPurchaseError = nil
        }) {
            let package = directConversionPackage
            TrialOfferSheet(
                focus: trialOfferFocus,
                // Only pass a trial label when this Apple ID is still eligible —
                // otherwise the sheet frames a straight yearly purchase.
                offerLabel: package.flatMap { store.eligibleIntroLabel(for: $0) },
                priceLabel: package?.vo2PriceLabel,
                ctaTitle: trialCTATitle(for: package),
                disclosureText: trialDisclosure(for: package),
                directPurchase: package != nil,
                isPurchasing: trialPurchaseInFlight,
                errorMessage: trialPurchaseError,
                onStartTrial: { startDirectTrialPurchase() },
                onDismiss: { showTrialOffer = false }
            )
            .presentationDetents([.fraction(0.68), .large], selection: $trialOfferDetent)
            .presentationDragIndicator(.visible)
            .interactiveDismissDisabled(trialPurchaseInFlight)
        }
        .sheet(item: $reportPreview) { preview in
            PDFPreviewSheet(title: preview.title, url: preview.url, shareText: preview.shareText)
        }
    }

    /// Always the yearly package. StoreKit applies the free trial when eligible;
    /// used-trial accounts pay the yearly price on the same product — no separate
    /// SKU and no nested plan picker required.
    private var directConversionPackage: Package? {
        store.yearlyPackage ?? store.packages.first
    }

    /// Present the personalized trial offer sheet, leading with the capability
    /// the user just reached for. Mirrors the Vitals+ settings behavior.
    private func presentTrialOffer(focus: PlusFeature? = nil) {
        trialOfferFocus = focus
        trialPurchaseError = nil
        trialOfferDetent = .fraction(0.68)
        showTrialOffer = true
    }

    private func trialCTATitle(for package: Package?) -> String {
        guard let package else { return "Continue with VO2+" }
        return VO2ConversionCopy.ctaLabel(
            trialLabel: package.vo2IntroOfferLabel,
            priceLabel: package.vo2PriceLabel,
            eligibleForTrial: store.isEligibleForIntroOffer(package)
        )
    }

    private func trialDisclosure(for package: Package?) -> String? {
        guard let package else { return nil }
        return VO2ConversionCopy.sheetDisclosure(
            trialLabel: package.vo2IntroOfferLabel,
            priceLabel: package.vo2PriceLabel,
            eligibleForTrial: store.isEligibleForIntroOffer(package)
        )
    }

    /// Buy the yearly product in place (Apple confirm sheet). The trial applies
    /// only when eligible; otherwise it's a straight yearly purchase. Falls back
    /// to the full plan picker if products never loaded.
    private func startDirectTrialPurchase() {
        guard let package = directConversionPackage else {
            showTrialOffer = false
            paywallFocus = trialOfferFocus
            showPaywall = true
            return
        }
        trialPurchaseError = nil
        trialPurchaseInFlight = true
        Task { @MainActor in
            defer { trialPurchaseInFlight = false }
            switch await store.purchase(package) {
            case .purchased, .pending:
                showTrialOffer = false
            case .cancelled, .none:
                trialPurchaseError = store.errorMessage
            }
        }
    }

    /// Opens the Apple Health app, where read-only access toggles live (profile ›
    /// Privacy › Apps). Read-only apps don't get a Health row under Settings ›
    /// [app], and iOS never re-presents the one-time permission sheet.
    private func openAppleHealth() {
        if let url = URL(string: "x-apple-health://") {
            UIApplication.shared.open(url)
        }
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
                openAppleHealth()
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
            Text("VO2 Max reads cardio fitness estimates from Apple Health, read-only. iOS shows the permission prompt only once. If VO2 max isn't connecting, open Apple Health › profile picture › Privacy › Apps › VO2 Max Daily Tracker and turn VO2 max on. \"Connected\" appears once a reading has been read.")
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
                    presentTrialOffer()
                } label: {
                    Label(store.shortConversionCTALabel, systemImage: "sparkles")
                }
            }

            // Reading alerts
            proToggle(
                feature: .readingAlerts,
                isOn: Binding(
                    get: { settings.readingAlertsEnabled },
                    set: { newValue in
                        settings.readingAlertsEnabled = newValue
                        if newValue { Task { await NotificationService.requestAuthorization() } }
                    }
                )
            )

            // Monthly recap
            proToggle(
                feature: .monthlyRecap,
                isOn: Binding(
                    get: { settings.monthlyRecapEnabled },
                    set: { settings.monthlyRecapEnabled = $0 }
                )
            )

            // Shareable report
            if store.isPro {
                Button {
                    generateReport()
                } label: {
                    HStack {
                        Label("Export fitness report", systemImage: "doc.richtext")
                        Spacer()
                        if isGeneratingReport { ProgressView() }
                    }
                }
                .disabled(isGeneratingReport || points.isEmpty)
            } else {
                Button {
                    presentTrialOffer(focus: .reports)
                } label: {
                    lockedRow(feature: .reports)
                }
            }

            if let reportError {
                Text(reportError)
                    .font(.caption)
                    .foregroundStyle(Theme.negative)
            }

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
                ? "Reading alerts and the monthly recap keep your cardio fitness in view between Apple Health estimates. Premium context also appears inside Today, Trends, and the VO2+ hub."
                : "Your latest estimate, basic cardio fitness trend, widgets, and Watch experience remain free. VO2+ adds alerts, a monthly recap, deeper trends, and a shareable report.")
        }
    }

    private var feedbackSection: some View {
        Section {
            Button {
                ReviewPromptCoordinator.shared.requestEnjoymentPrompt()
                dismiss()
            } label: {
                Label("Rate VO2 Max", systemImage: "star")
            }
            Button {
                ReviewPromptCoordinator.shared.requestFeedback()
                dismiss()
            } label: {
                Label("Send feedback", systemImage: "envelope")
            }
        } header: {
            Text("Support")
        } footer: {
            Text("Feedback opens your mail app with a private draft. No analytics, no account.")
        }
    }

    /// Locked features read as real settings toggles. For non-subscribers the
    /// toggle always shows OFF (`get` returns false) and flipping it on never
    /// sticks — it snaps back and opens the personalized trial offer instead.
    /// Mirrors the Vitals+ gated-toggle pattern.
    @ViewBuilder
    private func proToggle(feature: PlusFeature, isOn: Binding<Bool>) -> some View {
        let gated = Binding(
            get: { store.isPro && isOn.wrappedValue },
            set: { newValue in
                if store.isPro {
                    isOn.wrappedValue = newValue
                } else if newValue {
                    presentTrialOffer(focus: feature)
                }
            }
        )
        Toggle(isOn: gated) {
            Label {
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 6) {
                        Text(feature.title)
                            .font(.subheadline.weight(.semibold))
                        if !store.isPro {
                            Image(systemName: "lock.fill")
                                .font(.caption2)
                                .foregroundStyle(Theme.textTertiary)
                        }
                    }
                    Text(feature.detail)
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
            } icon: {
                Image(systemName: feature.symbol).foregroundStyle(Theme.cardio)
            }
        }
        .tint(Theme.cardio)
    }

    private func lockedRow(feature: PlusFeature) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: feature.symbol)
                .foregroundStyle(Theme.cardio)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 1) {
                Text(feature.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text(feature.detail)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer(minLength: 8)
            Image(systemName: "lock.fill")
                .font(.caption)
                .foregroundStyle(Theme.textTertiary)
        }
    }

    private func generateReport() {
        guard !points.isEmpty else { return }
        isGeneratingReport = true
        reportError = nil

        let now = Date.now
        let calendar = Calendar.current
        let windowDays = 180
        let windowStart = calendar.date(byAdding: .day, value: -windowDays, to: now) ?? now
        let previousStart = calendar.date(byAdding: .day, value: -windowDays * 2, to: now) ?? now
        let current = points.filter { $0.date >= windowStart && $0.date <= now }
        let previous = points.filter { $0.date >= previousStart && $0.date < windowStart }
        let periodStart = current.map(\.date).min() ?? windowStart

        let report = CardioReportGenerator.make(
            title: "Cardio Fitness Report",
            periodStart: periodStart,
            periodEnd: now,
            points: current,
            previousPoints: previous,
            targetLower: settings.targetLower,
            targetUpper: settings.targetUpper,
            chronologicalAge: settings.chronologicalAge,
            referenceSex: settings.referenceSex,
            allPointsForTrend: points
        )

        do {
            let url = try CardioReportPDF.render(report)
            reportPreview = ReportPreview(
                title: report.title,
                url: url,
                shareText: CardioReportShareText.make(report: report)
            )
        } catch {
            reportError = "Could not generate the report. Please try again."
        }
        isGeneratingReport = false
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
