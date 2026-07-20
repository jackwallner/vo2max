import SwiftUI
@preconcurrency import RevenueCat

/// Static legal URLs shared by onboarding, Settings, and the paywall.
enum VO2Links {
    static let privacyPolicy = URL(string: "https://jackwallner.github.io/vo2max/privacy-policy.html")!
    static let standardEULA = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
}

/// First-run flow. Direct port of the Vitals onboarding structure: adaptive
/// system colors (no fixed painted background, so text/pickers render correctly
/// in light and dark), a welcome page that requests Health access on Continue,
/// a setup page, and a trial page whose primary CTA sits in the exact frame the
/// Continue button occupied (zero-shift, fixed-height legal footer slot).
struct OnboardingView: View {
    private enum Step {
        case welcome
        case profile
        case target
        case trial
    }

    @EnvironmentObject private var settings: GoalSettings
    @EnvironmentObject private var store: StoreService
    @StateObject private var health = HealthKitService.shared

    @State private var step: Step = .welcome
    @State private var hasRequestedHealthAccess = false
    @State private var isStartingTrial = false
    @State private var isRestoring = false
    @State private var trialError: String?
    /// Fallback: presented only when the yearly package failed to load, so the
    /// primary CTA is never a dead button.
    @State private var showPaywallFallback = false

    // Local edit buffers so a skipped setup leaves stored defaults untouched.
    @State private var age: Int = 35
    @State private var referenceSex: ReferenceSex = .unspecified
    @State private var targetLower: Double = 35
    @State private var targetUpper: Double = 45
    /// Once the user drags the target slider we stop re-anchoring it to age, so a
    /// deliberate choice is never overwritten by a later age tweak.
    @State private var hasEditedTarget = false

    var body: some View {
        VStack(spacing: 0) {
            if step == .trial {
                // Trial must NOT live in a ScrollView: Spacers need a bounded
                // height to center the pitch above the zero-shift CTA bar.
                trialPage
                    .padding(.horizontal, 24)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    Group {
                        switch step {
                        case .welcome: welcomePage
                        case .profile: profilePage
                        case .target: targetPage
                        case .trial: EmptyView()
                        }
                    }
                    .padding(.top, 48)
                    .padding(.bottom, 24)
                    .padding(.horizontal, 24)
                }
                .scrollBounceBehavior(.basedOnSize)
            }

            bottomBar
        }
        .background(Theme.background.ignoresSafeArea())
        .task {
            age = settings.chronologicalAge > 0 ? settings.chronologicalAge : 35
            referenceSex = settings.referenceSex
            // Seed the target from the age-anchored typical range so the target
            // step opens already tuned to the profile, no manual dialing needed.
            anchorTargetToAge()
            store.trackPaywallImpression(id: "vo2plus_onboarding_trial")
            #if DEBUG
            let args = ProcessInfo.processInfo.arguments
            if let idx = args.firstIndex(of: "-OnboardingPage"), idx + 1 < args.count,
               let p = Int(args[idx + 1]) {
                step = [Step.welcome, .profile, .target, .trial][min(max(p, 0), 3)]
            }
            #endif
        }
        // A direct purchase (or restore) that flips Pro on finishes onboarding.
        .onChange(of: store.isPro) { _, isPro in
            if isPro { finishOnboarding() }
        }
        .sheet(isPresented: $showPaywallFallback) { PaywallView() }
    }

    /// Persists edits and hands the app to the main tab view.
    private func finishOnboarding() {
        settings.chronologicalAge = age
        settings.referenceSex = referenceSex
        settings.targetLower = targetLower
        settings.targetUpper = targetUpper
        settings.hasCompletedSetup = true
    }

    /// Fire the HealthKit prompt once, when the user leaves the welcome screen —
    /// never on appear, so the first thing they see is our heads-up rather than
    /// the system permission sheet.
    private func requestHealthAccessIfNeeded() async {
        guard !hasRequestedHealthAccess else { return }
        hasRequestedHealthAccess = true
        do {
            try await health.requestAuthorization()
            // Warm the cache while the user finishes setup so the dashboard can
            // paint the instant onboarding completes.
            Task { await health.refreshCache() }
        } catch {
            // Non-fatal: the dashboard's empty state offers a retry.
        }
    }

    // MARK: - Pages

    private var welcomePage: some View {
        VStack(spacing: 28) {
            VStack(spacing: 12) {
                Image("OnboardingMark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 76, height: 76)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                Text("Welcome to VO2 Max")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .multilineTextAlignment(.center)
                Text("See your cardio fitness from Apple Health in one simple view.")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: 16) {
                WelcomePoint(
                    icon: "heart.fill",
                    color: Theme.cardio,
                    title: "Reads from Apple Health",
                    detail: "Next we'll ask permission to read your VO2 max estimates. The app only reads; it never writes anything back."
                )
                WelcomePoint(
                    icon: "lock.fill",
                    color: Theme.cardioBlue,
                    title: "Stays on your device",
                    detail: "Your health data never leaves your devices. No account, no cloud sync."
                )
                WelcomePoint(
                    icon: "applewatch",
                    color: Theme.positive,
                    title: "Glanceable",
                    detail: "Widgets and real Apple Watch complications keep your latest estimate in view."
                )
            }
        }
    }

    private var profilePage: some View {
        VStack(spacing: 28) {
            VStack(spacing: 8) {
                Image(systemName: "person.crop.circle")
                    .font(.system(size: 48))
                    .foregroundStyle(Theme.cardio)
                Text("About you")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .multilineTextAlignment(.center)
                Text("Optional. Your age and reference power the fitness age estimate and set a target range tuned to you. Change both later in Settings.")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            profileCard
        }
    }

    private var targetPage: some View {
        let typical = CardioFitnessAnalysis.typicalRange(age: age, referenceSex: referenceSex)
        return VStack(spacing: 28) {
            VStack(spacing: 8) {
                Image(systemName: "scope")
                    .font(.system(size: 48))
                    .foregroundStyle(Theme.cardio)
                Text("Your target range")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .multilineTextAlignment(.center)
                Text("Anchored to age \(age): typical cardio fitness for your profile is \(Int(typical.lowerBound.rounded()))–\(Int(typical.upperBound.rounded())) mL/kg/min. Fine-tune it if you like.")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            targetCard
        }
    }

    private var profileCard: some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: "person.crop.circle")
                    .foregroundStyle(Theme.cardio)
                Text("About you")
                    .font(.system(.headline, design: .rounded))
                Spacer()
                Text("\(age)")
                    .font(Theme.bigNumber(22))
                    .foregroundStyle(Theme.cardio)
            }
            AgeWheelPicker(age: $age)
            Picker("Reference", selection: $referenceSex) {
                Text("Female").tag(ReferenceSex.female)
                Text("Male").tag(ReferenceSex.male)
                Text("Not set").tag(ReferenceSex.unspecified)
            }
            .pickerStyle(.segmented)
        }
        .padding(16)
        .background(Theme.cardSurface.opacity(0.5), in: RoundedRectangle(cornerRadius: 14))
        // Re-anchor the target to the profile until the user overrides it, so the
        // target step always opens matched to the age they just picked.
        .onChange(of: age) { _, _ in anchorTargetToAge() }
        .onChange(of: referenceSex) { _, _ in anchorTargetToAge() }
    }

    private var targetCard: some View {
        let typical = CardioFitnessAnalysis.typicalRange(age: age, referenceSex: referenceSex)
        return VStack(spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Image(systemName: "scope")
                    .foregroundStyle(Theme.cardio)
                Text("Target range")
                    .font(.system(.headline, design: .rounded))
                Spacer()
                Text("\(Int(targetLower))–\(Int(targetUpper))")
                    .font(Theme.bigNumber(22))
                    .foregroundStyle(Theme.cardio)
            }
            Text("Typical for your profile: \(Int(typical.lowerBound.rounded()))–\(Int(typical.upperBound.rounded())) mL/kg/min")
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            RangeSlider(
                lowerValue: $targetLower,
                upperValue: $targetUpper,
                bounds: 20...70,
                referenceRange: typical
            )
        }
        .padding(16)
        .background(Theme.cardSurface.opacity(0.5), in: RoundedRectangle(cornerRadius: 14))
        .onChange(of: targetLower) { _, _ in hasEditedTarget = true }
        .onChange(of: targetUpper) { _, _ in hasEditedTarget = true }
    }

    /// Snap the target range to the age/reference-anchored typical band unless the
    /// user has manually dragged the slider.
    private func anchorTargetToAge() {
        guard !hasEditedTarget else { return }
        let typical = CardioFitnessAnalysis.typicalRange(age: age, referenceSex: referenceSex)
        targetLower = typical.lowerBound.rounded()
        targetUpper = typical.upperBound.rounded()
    }

    /// Final step: compact pitch centered above the zero-shift CTA bar.
    private var trialPage: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 8)

            VStack(spacing: 18) {
                Image(systemName: "sparkles")
                    .font(.system(size: 44))
                    .foregroundStyle(Theme.cardioGradient)

                VStack(spacing: 6) {
                    Text("Go further with VO2+")
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .multilineTextAlignment(.center)
                    Text("Your number, trend, and fitness age stay free. VO2+ adds deeper context on top:")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: 12) {
                    TrialSellingPoint(
                        icon: "chart.bar.xaxis",
                        color: Theme.cardio,
                        title: "Deep Trends",
                        detail: "Compare 30, 90, and 180-day windows side by side"
                    )
                    TrialSellingPoint(
                        icon: "scope",
                        color: Theme.cardioBlue,
                        title: "Target outlook",
                        detail: "Direction and broad timeframe toward your target"
                    )
                    TrialSellingPoint(
                        icon: "person.2.crop.square.stack",
                        color: Theme.positive,
                        title: "Age-reference context",
                        detail: "Broad typical-range context for your profile"
                    )
                    TrialSellingPoint(
                        icon: "trophy",
                        color: Theme.coral,
                        title: "Personal bests",
                        detail: "Keep your strongest estimate visible"
                    )
                }
            }

            Spacer(minLength: 8)
        }
    }

    // MARK: - Bottom bar (zero-shift primary CTA, ported from Vitals)

    private var bottomBar: some View {
        VStack(spacing: 12) {
            aboveButtonContent

            primaryButton

            // Fixed legal-footer slot. Identical view on every page so its
            // height never changes; only visible on the trial page.
            legalFooter
                .opacity(step == .trial ? 1 : 0)
                .allowsHitTesting(step == .trial)
                .accessibilityHidden(step != .trial)
        }
        .padding(.top, 12)
        .padding(.bottom, 24)
        .background(Theme.background)
    }

    @ViewBuilder
    private var aboveButtonContent: some View {
        switch step {
        case .welcome: welcomeTrustLine
        case .profile, .target: EmptyView()
        case .trial: trialSoftExitAndDisclosure
        }
    }

    @ViewBuilder
    private var primaryButton: some View {
        switch step {
        case .welcome:
            Button {
                Task { await requestHealthAccessIfNeeded() }
                withAnimation(.easeInOut(duration: 0.25)) { step = .profile }
            } label: {
                primaryLabel("Continue")
            }
            .padding(.horizontal, 24)
        case .profile:
            Button {
                settings.chronologicalAge = age
                settings.referenceSex = referenceSex
                anchorTargetToAge()
                withAnimation(.easeInOut(duration: 0.25)) { step = .target }
            } label: {
                primaryLabel("Continue")
            }
            .padding(.horizontal, 24)
        case .target:
            Button {
                settings.targetLower = targetLower
                settings.targetUpper = targetUpper
                withAnimation(.easeInOut(duration: 0.25)) { step = .trial }
            } label: {
                primaryLabel("Continue")
            }
            .padding(.horizontal, 24)
        case .trial:
            Button {
                startTrial()
            } label: {
                ZStack {
                    primaryLabel(trialCTATitle)
                        .opacity(isStartingTrial ? 0 : 1)
                    if isStartingTrial {
                        ProgressView().tint(.white)
                    }
                }
            }
            .disabled(isStartingTrial)
            .padding(.horizontal, 24)
        }
    }

    private func primaryLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(.headline, design: .rounded))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Theme.cardio, in: RoundedRectangle(cornerRadius: 14))
            .foregroundStyle(.white)
    }

    private var welcomeTrustLine: some View {
        HStack(spacing: 5) {
            Image(systemName: "lock.fill")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Theme.cardio)
            Text("Read-only. Stays on your device. No account.")
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(Theme.textTertiary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 24)
        .accessibilityElement(children: .combine)
    }

    /// Trial-page content ABOVE the primary button: the de-emphasized free
    /// exit, then disclosure or error — none of it can shift the CTA.
    private var trialSoftExitAndDisclosure: some View {
        VStack(spacing: 12) {
            Button {
                finishOnboarding()
            } label: {
                Text("Get Started")
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .foregroundStyle(Theme.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)

            // Render no disclosure until the package loads — never a phantom
            // price. Error replaces disclosure in the same slot.
            if let trialError {
                Text(trialError)
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(Theme.negative)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            } else if let disclosure = trialDisclosure {
                Text(disclosure)
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(Theme.textTertiary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 24)
            }
        }
    }

    private var legalFooter: some View {
        HStack(spacing: 14) {
            Button(isRestoring ? "Restoring…" : "Restore") { startRestore() }
                .buttonStyle(.plain)
                .disabled(isRestoring)
            Link("Terms", destination: VO2Links.standardEULA)
            Link("Privacy", destination: VO2Links.privacyPolicy)
        }
        .font(.system(.caption2, design: .rounded, weight: .semibold))
        .foregroundStyle(Theme.textTertiary)
    }

    // MARK: - Trial copy

    private var trialCTATitle: String {
        if let yearly = store.yearlyPackage, let label = store.eligibleIntroLabel(for: yearly) {
            return "Start \(label)"
        }
        return "Continue with VO2+"
    }

    private var trialDisclosure: String? {
        guard let yearly = store.yearlyPackage else { return nil }
        return VO2ConversionCopy.disclosure(
            trialLabel: yearly.vo2IntroOfferLabel,
            priceLabel: yearly.vo2PriceLabel,
            eligibleForTrial: store.isEligibleForIntroOffer(yearly)
        )
    }

    // MARK: - Actions

    private func startTrial() {
        guard let yearly = store.yearlyPackage else {
            showPaywallFallback = true
            return
        }
        trialError = nil
        isStartingTrial = true
        Task {
            _ = await store.purchase(yearly)
            isStartingTrial = false
            if let message = store.errorMessage { trialError = message }
            // Success routes through onChange(store.isPro) -> finishOnboarding().
        }
    }

    private func startRestore() {
        isRestoring = true
        trialError = nil
        Task {
            await store.restore()
            isRestoring = false
            if store.isPro { finishOnboarding() }
            else { trialError = store.errorMessage ?? "No active VO2+ purchase was found." }
        }
    }
}

private struct WelcomePoint: View {
    let icon: String
    let color: Color
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                Text(detail)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.cardSurface.opacity(0.5), in: RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .combine)
    }
}

/// Compact selling point for the onboarding trial step (Vitals pattern).
private struct TrialSellingPoint: View {
    let icon: String
    let color: Color
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.14), in: RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text(detail)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }
}
