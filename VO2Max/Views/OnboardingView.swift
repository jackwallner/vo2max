import SwiftUI
@preconcurrency import RevenueCat

/// The first-run flow, presented as the root view (not a sheet) so pages simply
/// *exist* rather than swiping up from the bottom. The user learns what the app
/// does, sets an optional reference profile and target, connects Apple Health,
/// and lands on a trial page that reads as the final onboarding step.
///
/// The primary CTA sits in a byte-identical frame on every page via
/// `OnboardingBottomBar` (see the thumb-zone contract), so the trial CTA lands
/// exactly where "Continue" was — no thumb travel, no context switch.
struct OnboardingView: View {
    @EnvironmentObject private var settings: GoalSettings
    @EnvironmentObject private var store: StoreService
    @StateObject private var health = HealthKitService.shared

    @State private var page = 0
    @State private var isConnecting = false
    @State private var isPurchasing = false
    @State private var isRestoring = false
    @State private var errorMessage: String?
    @State private var showFallbackPaywall = false

    // Local edit buffers so declining leaves the stored defaults untouched.
    @State private var age: Int = 35
    @State private var referenceSex: ReferenceSex = .unspecified
    @State private var targetLower: Double = 35
    @State private var targetUpper: Double = 45

    private let trialPage = 4

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                welcomePage.tag(0)
                profilePage.tag(1)
                targetPage.tag(2)
                healthPage.tag(3)
                trialPage_.tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: page)

            bottomBar
        }
        .background(Theme.onboardingBackground)
        .foregroundStyle(Theme.onboardingPrimaryText)
        // Onboarding owns a fixed visual theme. Input controls use explicit light
        // surfaces and dark text, so they never inherit a dark-mode system-gray
        // treatment before the user has chosen an app appearance.
        .environment(\.colorScheme, .light)
        .task {
            age = settings.chronologicalAge > 0 ? settings.chronologicalAge : 35
            referenceSex = settings.referenceSex
            targetLower = settings.targetLower
            targetUpper = settings.targetUpper
            store.trackPaywallImpression(id: "vo2plus_onboarding_trial")
            #if DEBUG
            let args = ProcessInfo.processInfo.arguments
            if let idx = args.firstIndex(of: "-OnboardingPage"), idx + 1 < args.count,
               let p = Int(args[idx + 1]) {
                page = min(max(p, 0), trialPage)
            }
            #endif
        }
        .onChange(of: store.isPro) { _, isPro in if isPro { finish() } }
        .sheet(isPresented: $showFallbackPaywall) { PaywallView() }
    }

    // MARK: - Bottom bar (zero-shift primary CTA)

    private var bottomBar: some View {
        OnboardingBottomBar(
            primaryTitle: primaryTitle,
            isBusy: (page == 3 && isConnecting) || (page == trialPage && isPurchasing),
            isDisabled: isConnecting || isPurchasing || isRestoring,
            primaryAction: primaryAction,
            footer: page == trialPage
                ? OnboardingLegalFooter(isRestoring: isRestoring, onRestore: startRestore)
                : OnboardingLegalFooter(isPlaceholder: true)
        ) {
            VStack(spacing: 10) {
                if page == 3 {
                    softExit("Skip for now") { advance() }
                } else if page == trialPage {
                    softExit("Get Started") { finish() }
                    if let disclosure = trialDisclosure {
                        Text(disclosure)
                            .font(.caption2)
                            .foregroundStyle(Theme.onboardingSecondaryText)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                } else {
                    pageDots
                }
                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption2)
                        .foregroundStyle(Theme.negative)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }

    private var primaryTitle: String {
        switch page {
        case 3: return health.isAuthorized ? "Continue" : "Connect Apple Health"
        case trialPage: return trialCTATitle
        default: return "Continue"
        }
    }

    private func primaryAction() {
        switch page {
        case 1: settings.chronologicalAge = Int(age); settings.referenceSex = referenceSex; advance()
        case 2: settings.targetLower = targetLower; settings.targetUpper = targetUpper; advance()
        case 3: connectHealth()
        case trialPage: startTrial()
        default: advance()
        }
    }

    private func advance() { withAnimation { page = min(page + 1, trialPage) } }

    private func finish() {
        // Persist any edits the user made but didn't explicitly commit via
        // Continue — e.g. adjusting age/target then swiping the pager forward
        // and tapping Get Started. Declined pages just rewrite the defaults.
        settings.chronologicalAge = age
        settings.referenceSex = referenceSex
        settings.targetLower = targetLower
        settings.targetUpper = targetUpper
        settings.hasCompletedSetup = true
    }

    private func softExit(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Theme.onboardingMuted)
                .frame(maxWidth: .infinity)
                .frame(height: 30)
        }
        .buttonStyle(.plain)
        .disabled(isPurchasing || isConnecting)
    }

    private var pageDots: some View {
        HStack(spacing: 8) {
            ForEach(0...trialPage, id: \.self) { i in
                Circle()
                    .fill(i == page ? Theme.cardio : Theme.secondaryText.opacity(0.3))
                    .frame(width: 7, height: 7)
            }
        }
        .frame(height: 30)
    }

    // MARK: - Pages

    private var welcomePage: some View {
        pageScaffold {
            iconGlyph
            Text("Your cardio fitness, at a glance")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            Text("See your latest Apple Health VO2 max estimate, understand where your trend is heading, and keep it on your Home Screen and Apple Watch.")
                .font(.body)
                .foregroundStyle(Theme.onboardingSecondaryText)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            VStack(spacing: 10) {
                featureCard("waveform.path.ecg", "Focused", "One calm dashboard, not a training platform")
                featureCard("lock.shield", "Private", "Your fitness data stays on your devices")
                featureCard("applewatch", "Glanceable", "Widgets and real Watch complications")
            }
            .padding(.top, 4)
        }
    }

    private var profilePage: some View {
        pageScaffold {
            Text("A little about you")
                .font(.title.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Optional. Used only to estimate your fitness age and typical-range context. You can skip this and set it later.")
                .font(.subheadline)
                .foregroundStyle(Theme.onboardingSecondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Age").font(.headline)
                    Spacer()
                    Text("\(age)").font(Theme.numberFont(24)).foregroundStyle(Theme.cardioBlue)
                }
                AgeWheelPicker(age: $age, textColor: Theme.onboardingInputText)
            }
            .foregroundStyle(Theme.onboardingInputText)
            .padding(16)
            .background(Theme.onboardingInputCard, in: RoundedRectangle(cornerRadius: Theme.cardRadius))

            VStack(alignment: .leading, spacing: 10) {
                Text("Reference").font(.headline)
                referenceControl
            }
            .foregroundStyle(Theme.onboardingInputText)
            .padding(16)
            .background(Theme.onboardingInputCard, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
        }
    }

    private var targetPage: some View {
        pageScaffold {
            Text("Set a target range")
                .font(.title.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("A personal fitness target, not a medical threshold. It drives the Today ring and Trends band. Keep the default if you're not sure.")
                .font(.subheadline)
                .foregroundStyle(Theme.onboardingSecondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 16) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Target").font(.headline)
                    Spacer()
                    Text("\(Int(targetLower))–\(Int(targetUpper))")
                        .font(Theme.numberFont(26)).foregroundStyle(Theme.cardioBlue)
                    Text("mL/kg/min")
                        .font(.caption)
                        .foregroundStyle(Theme.onboardingInputSecondaryText)
                }
                let typical = CardioFitnessAnalysis.typicalRange(age: age, referenceSex: referenceSex)
                Text("Typical range for your age: \(Int(typical.lowerBound.rounded()))–\(Int(typical.upperBound.rounded())) mL/kg/min")
                    .font(.caption)
                    .foregroundStyle(Theme.onboardingInputSecondaryText)
                RangeSlider(
                    lowerValue: $targetLower,
                    upperValue: $targetUpper,
                    bounds: 20...70,
                    tint: Theme.cardioBlue,
                    handleColor: .white,
                    referenceRange: typical
                )
            }
            .foregroundStyle(Theme.onboardingInputText)
            .padding(18)
            .background(Theme.onboardingInputCard, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
        }
    }

    private var healthPage: some View {
        pageScaffold {
            iconGlyph
            Text("Connect Apple Health")
                .font(.title.bold())
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            Text("VO2 Max reads your cardio fitness estimates from Apple Health, read-only. Nothing is written back, and your data never leaves your devices.")
                .font(.body)
                .foregroundStyle(Theme.onboardingSecondaryText)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            VStack(spacing: 10) {
                featureCard("heart.fill", "Read-only", "We only read your VO2 max estimates")
                featureCard("bolt.horizontal", "Automatic", "New readings sync in on their own")
            }
            .padding(.top, 4)
            if health.isAuthorized {
                Label("Apple Health connected", systemImage: "checkmark.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.positive)
            }
            Text("Fitness estimates are not medical measurements. This app does not diagnose or treat health conditions.")
                .font(.caption2)
                .foregroundStyle(Theme.onboardingSecondaryText)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.top, 4)
        }
    }

    private var trialPage_: some View {
        pageScaffold {
            iconGlyph
            Text(trialHeadline)
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            Text("Compare periods, understand your direction toward target, see broad age-reference context, and recognize personal bests. Your latest estimate and basic trend stay free.")
                .font(.body)
                .foregroundStyle(Theme.onboardingSecondaryText)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            VStack(spacing: 10) {
                benefitCard("chart.bar.xaxis", "Compare periods", "See each window beside the matching one before it")
                benefitCard("scope", "Understand direction", "Put your recent cardio fitness trend in target context")
                benefitCard("person.2.crop.square.stack", "Add broad context", "See typical-range context for your age and reference")
                benefitCard("trophy", "Recognize progress", "Keep your personal best visible as readings build")
            }
            .padding(.top, 4)
        }
    }

    // MARK: - Building blocks

    /// Custom segmented control themed to the fixed onboarding input palette.
    /// Drawing it ourselves prevents system appearance from turning the control
    /// gray or reducing contrast before the user selects an app theme.
    private var referenceControl: some View {
        HStack(spacing: 4) {
            referenceSegment("Female", .female)
            referenceSegment("Male", .male)
            referenceSegment("Not set", .unspecified)
        }
        .padding(4)
        .background(Theme.onboardingInputTrack, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func referenceSegment(_ title: String, _ value: ReferenceSex) -> some View {
        let isSelected = referenceSex == value
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) { referenceSex = value }
        } label: {
            Text(title)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .lineLimit(1)
                .minimumScaleFactor(0.55)
                .foregroundStyle(isSelected ? Color.white : Theme.onboardingInputText)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(
                    isSelected ? Theme.cardioBlue : Color.clear,
                    in: RoundedRectangle(cornerRadius: 9, style: .continuous)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var iconGlyph: some View {
        Image("OnboardingMark")
            .resizable()
            .scaledToFit()
            .frame(width: 84, height: 84)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .frame(maxWidth: .infinity)
    }

    private func pageScaffold<Content: View>(@ViewBuilder _ content: @escaping () -> Content) -> some View {
        GeometryReader { geo in
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    content()
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                .frame(maxWidth: .infinity, minHeight: geo.size.height, alignment: .center)
            }
        }
    }

    private func featureCard(_ symbol: String, _ title: String, _ detail: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(Theme.cardio)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(Theme.onboardingSecondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.onboardingCard, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
    }

    private func benefitCard(_ symbol: String, _ title: String, _ detail: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(Theme.cardio)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.bold())
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(Theme.onboardingSecondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.onboardingCard, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
    }

    // MARK: - Trial copy

    private var trialHeadline: String {
        (store.yearlyPackage.flatMap { store.eligibleIntroLabel(for: $0) } != nil) ? "Try VO2+ free" : "Unlock VO2+"
    }

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

    private func connectHealth() {
        isConnecting = true
        errorMessage = nil
        Task {
            do { try await health.requestAuthorization() }
            catch { errorMessage = "Apple Health access could not be completed." }
            isConnecting = false
            advance()
        }
    }

    private func startTrial() {
        guard let yearly = store.yearlyPackage else {
            showFallbackPaywall = true
            return
        }
        errorMessage = nil
        isPurchasing = true
        Task {
            _ = await store.purchase(yearly)
            isPurchasing = false
            if let message = store.errorMessage { errorMessage = message }
            // Success routes through onChange(store.isPro) -> finish().
        }
    }

    private func startRestore() {
        isRestoring = true
        errorMessage = nil
        Task {
            await store.restore()
            isRestoring = false
            if store.isPro { finish() }
            else { errorMessage = store.errorMessage ?? "No active VO2+ purchase was found." }
        }
    }
}
