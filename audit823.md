# VO2 Max & Cardio Fitness audit823

Audit date: 2026-08-23

Scope: VO2 Max & Cardio Fitness in /Users/jackwallner/health only.

This is a fresh max-reasoning rerun. The audit covers download conversion, trial starts, purchase and RevenueCat behavior, user experience, ratings, App Store metadata, the marketing site, legal copy, HealthKit behavior, release regression signals, health compliance, and the documentation contract for Cursor, Claude, and Codex.

No app source, configuration, metadata, website, or documentation file was changed. The only intended write is this file. No commit or push was performed.

## Executive verdict

The app has a coherent product story, a polished local-first UI, a thoughtful review prompt flow, and a valid basic StoreKit product set. The largest risks are not a missing feature. They are source-of-truth drift and measurement ambiguity around the paid funnel.

The most urgent work is to reconcile the RevenueCat catalog with the local and App Store product model, make pending and failed purchases visible to users, and verify background HealthKit delivery through a cold app and watch/widget scenario. The current evidence does not prove a live crash spike, but the repository does not contain a production crash or release watchdog that would make such a spike visible to the implementation agent.

The next implementation agent should treat the following as release gates:

1. Reconcile the lifetime product type, price references, entitlement identifier, and review notes across RevenueCat, StoreKit, App Store Connect scripts, and the app.
2. Test monthly, yearly, lifetime, restore, pending, cancellation, offering-load failure, and offline states with user-visible outcomes.
3. Validate a new HealthKit VO2 max sample while the iPhone app is not open, including widget, watch, and cold relaunch freshness.
4. Replace the AGENTS.md versus CLAUDE.md split with one canonical agent contract and one simulator naming convention.
5. Add funnel attribution before interpreting trial-start or paywall conversion results.

## Evidence convention and limits

- Observed means directly found in local files or in the authenticated App Store Connect, public App Store, or RevenueCat pages inspected on 2026-08-23.
- Inference means a likely risk derived from observed code or copy. It still needs a runtime or account-level check.
- Validate means the audit found insufficient evidence to conclude either way.
- RevenueCat dashboard figures below are point-in-time snapshots, not cohort conversion rates.
- The public App Store listing showed the latest public release and ratings state, but the full private App Store Connect distribution screen did not render its detailed content in the browser session.
- No production crash telemetry, MetricKit export, Crashlytics export, or live user session stream was available in the repository or inspected context. A crash spike therefore cannot be ruled in or ruled out.
- The request explicitly excludes treating the App Store Data Not Collected label versus RevenueCat transaction processing as an issue. That topic is not raised as a defect in this audit.
- This audit does not recommend diagnosis, treatment, cure, prevention, or clinical outcome claims. Product copy should stay within a fitness tracking and educational framing.

## Live evidence snapshot

### App Store and repository state

Observed:

- App Store ID: 6791235742.
- Bundle ID: com.jackwallner.vo2max.
- Public app name: VO2 Max & Cardio Fitness.
- Public version: 1.1.1.
- App Store Connect app list state: Ready for Distribution.
- Public storefront state: version 1.1.1, free with in-app purchases.
- The public listing said there were not enough ratings or reviews to display an overview.
- The repository project is MARKETING_VERSION 1.1.2 and CURRENT_PROJECT_VERSION 47 in project.yml.
- scripts/.asc-state.json says draftVersion 1.1.1, liveVersion 1.1.0, and was updated 2026-08-11. Those values are behind both the public listing and the repository.
- The last repository commit is 0b08562, “chore: bump to 1.1.2 build 47 for TestFlight”.

Implication:

The public product, the release-state helper file, and the current repository are not describing the same release. This is a release-operations risk and a source-of-truth risk. It is not proof that the binary in distribution is broken.

### RevenueCat state

Observed in RevenueCat project 9ca6f38c, project name VO2 Max & Cardio Fitness, on 2026-08-23:

- Active trials: 1.
- Active subscriptions: 3.
- MRR: 4 USD.
- Revenue in the last 28 days: 45 USD.
- New customers in the last 28 days: 61.
- Active customers in the last 28 days: 83.
- Recent transactions included a US monthly trial, a converted US yearly trial at 14.99 USD, and a converted Taiwan yearly transaction at 15.19 USD.
- RevenueCat Paywalls showed “No paywalls yet”.
- RevenueCat Experiments showed “No experiments yet”.
- The default offering is default, display name VO2+, with three packages and no attached Paywall.
- The package IDs are $rc_monthly, $rc_annual, and $rc_lifetime.
- The product identifiers are com.jackwallner.vo2max.monthly, com.jackwallner.vo2max.yearly, and com.jackwallner.vo2max.pro.lifetime.
- The RevenueCat entitlement UI displayed “V02 Max Pro”, with a zero-looking spelling in the label, while the app source uses the expected entitlement string pro. The source currently unlocks on any active entitlement instead of checking the expected identifier.
- The RevenueCat yearly and lifetime product pages showed Approved. The monthly product page showed Loading in the captured state.
- RevenueCat displayed the lifetime product as Product Type Non-renewing Subscription. The local StoreKit file and ASC setup script model lifetime as a non-consumable product.
- RevenueCat showed no lifetime transactions in the captured product view.

Implication:

The dashboard values show that the paid path is live and has real activity, but the sample is too small to infer trial conversion, retention, or pricing performance. The catalog type mismatch and entitlement naming ambiguity must be resolved before running pricing or paywall experiments.

## Priority register

| Priority | Finding | Evidence | Risk | Required outcome |
| --- | --- | --- | --- | --- |
| P0 | RevenueCat lifetime type and source-of-truth price drift | VO2Max.storekit says lifetime non-consumable at 59.99 USD. scripts/asc-setup-release.py contains 29.99 USD. RevenueCat labels lifetime non-renewing subscription. | Wrong purchase behavior, incorrect entitlement lifecycle, broken restore or analytics, review confusion | One product contract with identifier, type, price schedule, entitlement, copy, and validation owner. |
| P0 | Purchase pending state is not reliably communicated | StoreService.purchase can return pending. Onboarding ignores the result. Settings treats purchased and pending as success. Paywall has no pending state. | A user can leave the paywall believing access was granted or the trial began when it did not | Pending is a first-class screen state with a clear next action and no false completion. |
| P0 | Background HealthKit delivery needs a cold-start validation, especially on watch | iOS App.init calls enableBackgroundDelivery. Watch App.swift does not. The shared observer only observes VO2 max. | Widgets, watch, or cache can remain stale after a background sample or context update | Demonstrate fresh data after a background sample without opening the iPhone app, or document a supported limitation. |
| P0 | Agent documentation has conflicting simulator and background rules | AGENTS.md and CLAUDE.md are separate regular files. They disagree on the simulator label, and only CLAUDE.md contains the critical App.init observer rule. | Cursor, Claude, and Codex can run different commands or reintroduce the old background bug | One canonical documentation file, one symlink or generated mirror, one simulator slug. |
| P1 | Paywall impressions are misattributed | Onboarding logs vo2plus_onboarding_trial during .task before the trial step. Focused PaywallView instances use the default vo2plus_paywall ID. Settings TrialOfferSheet has no custom paywall impression. | Trial-start and conversion rates have invalid denominators and cannot identify the best entry point | Instrument impressions only when visible and attach entry, focus, package, and eligibility. |
| P1 | Monthly versus yearly trial strategy is inconsistent | Onboarding buys monthly. Settings direct conversion buys yearly. Full Paywall defaults to yearly. | Cohorts have different price, renewal, and trial experiences without an explicit experiment design | Choose a control path, document intentional variants, and assign stable cohorts. |
| P1 | Free versus VO2+ feature copy is inconsistent | Dashboard and onboarding expose fitness age and target range to free users. docs/index.html labels target range and fitness age as VO2+ and says VO2+ unlocks them. | Storefront promise and in-app experience disagree, reducing trust and creating review risk | Publish one entitlement matrix and use it in app, site, screenshots, and metadata. |
| P1 | Repository release and review notes are stale | review_information/notes.txt describes build 35, build 43, and an annual-first onboarding screen. Current project is build 47 and onboarding buys monthly. | App Review receives misleading instructions and future agents copy old commerce assumptions | Regenerate review notes from current release facts before submission. |
| P1 | Supporting HealthKit context is foreground-only | CardioContextService loads RHR, HRR, and workouts on demand with a one-minute throttle and has no background observer or shared cache. | VO2+ context can look stale after new Health data arrives | Add a deliberate freshness strategy or clearly state when context refreshes. |
| P1 | Product and localization state is not reconciled | Local metadata has 50 locales and passes validation. Public App Store page showed English only. | Work may be spent optimizing translations that are not shipped, or shipped copy may be stale | Compare ASC localization state to the repository and make one decision per locale. |
| P2 | Public accessibility declaration is empty | Public listing said the developer had not indicated supported accessibility features. Existing handoff also lists large-text and dark-mode verification gaps. | Lower trust and lower conversion for accessibility-conscious users | Verify actual support, then declare only supported features and fix gaps. |
| P2 | Review funnel has no visible rating overview yet | App Store listing has insufficient ratings for an overview. The internal funnel is otherwise well staged. | Low social proof and limited store conversion data | Improve eligible prompt volume and measure each prompt outcome without interrupting activation. |
| P2 | Canonical marketing URL is ambiguous | ASC metadata uses jackwallner.github.io/vo2max. docs/index.html sets canonical to jackwallner.com/ios/vo2max. A workflow mirrors the site to a portfolio repository. | Search indexing and future agent edits can target different copies | Choose one canonical, redirect the other, and verify both on every release. |

## Product and release source of truth

### Current local product contract

Observed in project.yml:

- iOS deployment target is 17.0.
- watchOS deployment target is 10.0.
- Swift version is 6.0.
- RevenueCat purchases-ios-spm is configured from version 5.14.0.
- iOS bundle ID is com.jackwallner.vo2max.
- The iOS target includes VO2Max.storekit.
- The watch target excludes Shared/Services/StoreService.swift.
- The project defines iOS, widget, watch, and watch widget targets.
- App Group is group.com.jackwallner.vo2max.

Observed in VO2Max.storekit:

- Lifetime: com.jackwallner.vo2max.pro.lifetime, non-consumable, display price 59.99 USD.
- Monthly: com.jackwallner.vo2max.monthly, one-month subscription, seven-day free trial, display price 5.99 USD.
- Yearly: com.jackwallner.vo2max.yearly, one-year subscription, seven-day free trial, display price 29.99 USD.
- Monthly and yearly are in the VO2+ subscription group.

Observed in scripts/asc-setup-release.py:

- Lifetime identifier is com.jackwallner.vo2max.pro.lifetime.
- Lifetime description is “Unlock VO2+ forever. One payment.”
- The script contains PRICE = "29.99", which does not match the local lifetime StoreKit price.
- The script documentation still says it prepares VO2 Max 1.0 metadata.

Observed in scripts/asc-readiness.py:

- The readiness script still describes itself as an audit for VO2 Max 1.0.0.
- It checks product IDs, status, prices, offers, review screenshots, health and wellness rating, medical or treatment information, review notes, and exactly seven screenshots.
- It accepts PREPARE_FOR_SUBMISSION and READY_FOR_REVIEW.

Required decision:

Create one product contract, preferably generated or checked by a read-only consistency script. It should include:

- App Store product ID.
- RevenueCat product ID.
- Product type in StoreKit, ASC, and RevenueCat.
- Subscription group.
- Entitlement ID and display name.
- Price schedule and territory source.
- Intro offer eligibility and duration.
- Localized product label and disclosure.
- Which app surface selects the product.
- Expected restore and cancellation behavior.

Do not use a hard-coded price in a setup script as the authoritative value if ASC or StoreKit is the source of the live price. If a setup script must contain a price, it should fail loudly when the live catalog differs.

### Release state synchronization

The following state files and docs need a release update policy:

- scripts/.asc-state.json.
- scripts/.astro-app.json.
- README.md.
- docs/astro-aso-setup.md.
- fastlane/metadata/review_information/notes.txt.
- scripts/asc-readiness.py docstrings.
- scripts/asc-setup-release.py docstrings and price constants.
- fastlane/metadata/en-US/release_notes.txt.
- ios27VO2Max.md and the older .claude handoff.

The current state file says draft 1.1.1 and live 1.1.0, while the public listing says 1.1.1 and the project says 1.1.2 build 47. The implementation agent should decide whether 1.1.2 build 47 is in TestFlight only, waiting for review, or intended to replace the public build, then update the state evidence accordingly.

## Download and App Store conversion audit

### Current metadata

Observed:

- Name: VO2 Max & Cardio Fitness.
- Subtitle: Fitness Age & Cardio Trends.
- Keywords include healthkit, applewatch, tracker, performance, insights, recovery, aerobic, endurance, widget, history, and athlete.
- Primary category: Health & Fitness.
- Secondary category: Lifestyle.
- The local metadata validator reports 50 locales, 24 of 24 required fields, 94 or more ASO fields, URLs, and disclosures present.
- There are seven local en-US screenshot files, numbered 01_today through 07_watch.
- The public listing showed English only during the inspected session.
- The public product page showed iOS 17.0 or later, iPhone and Apple Watch support, 12.5 MB size, age 9+, and free with in-app purchases.

Strengths:

- The title contains both the product category and cardio fitness intent.
- The subtitle contains fitness age and trend language.
- The description clearly explains Apple Health input, local processing, history, widgets, Apple Watch, VO2+, optional plans, trial eligibility, renewal, and restore.
- The screenshot set has a coherent visual system. The inspected contact sheet shows a clear progression from today value, trend, fitness age, target range, history, and VO2+.
- The metadata validator is a useful release gate.

Risks and opportunities:

1. The public listing and repository localization state need reconciliation. Do not assume that 50 local metadata directories mean 50 live storefront localizations.
2. The first screenshot headline, “Your cardio fitness in one number”, is clear but does not explicitly mention Apple Health or VO2 max. Test an intent-led variant against the current creative, for example a headline that names VO2 max and Apple Health without making a clinical claim.
3. “Track it like an athlete” may convert well for performance-oriented users but may narrow the audience. Test a broader copy variant against an endurance-focused variant.
4. “Fitness age” and “target range” are high-interest terms but must use the same free or paid entitlement meaning everywhere.
5. The public accessibility section is empty. After verifying the real UI, declare only supported features such as VoiceOver, Dynamic Type, contrast, Reduce Motion, and larger text.
6. The release notes explain the monthly trial and annual per-month comparison, but the review notes describe a different annual-first flow.
7. The local metadata has many locale directories, while the public listing appeared English only. If the localizations are not submitted, either submit the high-value locales or remove stale metadata from the active path so agents do not treat it as live.

### ASO experiments

These are suggested tests, not claims that an experiment is currently running:

| Test | Control | Variant | Primary metric | Guardrail |
| --- | --- | --- | --- | --- |
| Title or subtitle intent | Fitness Age & Cardio Trends | A variant that explicitly names VO2 max and Apple Health | Product page conversion to download | Search impression quality and review sentiment |
| First screenshot | One number value proposition | Apple Health plus VO2 max value proposition | Product page conversion | Do not imply diagnosis or medical accuracy |
| Screenshot 5 | Track it like an athlete | A broader everyday fitness trend message | Product page conversion | Keep claims consistent with the actual feature |
| VO2+ screenshot | Go further with VO2+ | Specific paid benefit with price-neutral value framing | Product page conversion to trial start | Do not obscure trial terms or renewal |
| Localized listing | English copy | Highest-volume locale after ASC data confirms it is live | Locale-specific conversion | Translation review and legal disclosure parity |

For each test, preserve the app version and product configuration. Do not compare a metadata change against a simultaneous product price or onboarding change without labeling it as a confounded result.

## Website, terms, privacy, and listing consistency

### Canonical URL and mirrored site

Observed:

- App Store marketing URL is https://jackwallner.github.io/vo2max/.
- Public listing Developer Website points to the GitHub Pages URL.
- docs/index.html sets a canonical URL of https://jackwallner.com/ios/vo2max/.
- The repository has a GitHub workflow that mirrors the site to a portfolio repository.
- JSON-LD and download links use the App Store ID 6791235742.

Required validation:

- Fetch both URL families from a clean browser session.
- Compare title, description, version-independent product copy, terms URL, privacy URL, App Store link, and image assets.
- Confirm whether one URL redirects to the other.
- Choose one canonical URL for ASC, metadata, JSON-LD, and search indexing.
- Add a consistency check that fails when the canonical URL, App Store URL, terms URL, or privacy URL changes in one surface but not another.

### Entitlement matrix drift

Observed in docs/index.html:

- Target range is labeled “VO2+”.
- Fitness age is labeled “VO2+”.
- A screenshot alt says VO2+ unlocks fitness age, targets, and full history.
- The page pitches current value, trend, target, year history, and fitness age in adjacent sections without a single complete free versus paid matrix.

Observed in app source:

- DashboardView.fitnessAgeCard is not gated on store.isPro.
- DashboardView displays the latest estimate, trend, fitness age, and target-related content to the free user.
- OnboardingView says the number, trend, and fitness age stay free.
- Plus screens gate deeper trends, target projection, broad fitness context, alerts, recap, reports, and other context.

Inference:

The site likely reflects an older entitlement plan. It may be intentionally describing target range or fitness age context as paid while the current app exposes a basic version for free, but the distinction is not explained.

Required outcome:

Define an entitlement matrix with rows for:

- Latest estimate.
- Basic trend.
- One-year history.
- Target range display.
- Target projection or outlook.
- Fitness age number.
- Fitness age context or band.
- RHR, HRR, workouts, and cardio drivers.
- Freshness.
- Alerts.
- Monthly recap.
- Reports or export.
- Widgets.
- Apple Watch app.

Use the same matrix in DashboardView copy, PlusTabView, onboarding, docs/index.html, screenshots, ASC description, and review notes. If the number is free and the context is paid, say that explicitly.

### Terms and privacy

Observed:

- docs/terms.html was updated 2026-08-17.
- Terms include an Apple Standard EULA, fitness disclaimer, subscription renewal, lifetime one-time purchase, Apple billing, cancellation, restore, and a statement that prices and offers are shown before purchase.
- docs/privacy-policy.html was updated 2026-08-17.
- Privacy copy describes VO2 max and optional RHR, HRR, and workout reads, local processing, Apple and RevenueCat transaction handling, and no HealthKit values sent to RevenueCat.
- docs/support.html explains Health access, no estimate troubleshooting, restore purchases, Apple billing support, and not sending health records to support.
- ASC metadata links terms through the EULA convention and links privacy and support pages.

Checks:

- Confirm every locale has the same terms and privacy URLs.
- Confirm terms and privacy pages are reachable over HTTPS with valid certificates.
- Confirm all site copies use “fitness” and “educational” language rather than clinical outcome language.
- Confirm the product disclosure in onboarding, Settings, PaywallView, TrialOfferSheet, ASC description, terms, and the site all agree on monthly versus yearly offer presentation.
- Confirm support and feedback email aliases both deliver to an actively monitored inbox. The support pages use jackwallner@gmail.com, while ReviewPromptSheet.feedbackMailURL uses jackwallner+vo2@gmail.com. This may be intentional, but it is not documented.

Excluded by request:

The App Store Data Not Collected label and RevenueCat transaction processing are not treated as an inconsistency finding here.

## Activation and trial-start flow

### Current sequence

Observed in VO2Max/App.swift and VO2Max/Views/OnboardingView.swift:

1. App.init configures the notification delegate, records a launch, and calls HealthKitService.shared.enableBackgroundDelivery().
2. RootView chooses the onboarding flow when setup has not completed.
3. Onboarding steps are welcome, profile, target, and trial.
4. Leaving the welcome step requests HealthKit read authorization for VO2 max and optional context types.
5. Profile fields include optional age and reference sex. The target range is anchored to a typical range and remains editable.
6. The onboarding trial step says the number, trend, and fitness age stay free, then presents VO2+ benefits.
7. OnboardingView selects the monthly package and calls StoreService.purchase.
8. A successful isPro change finishes onboarding.
9. Restore is available in the trial footer.
10. If the monthly package is unavailable, the UI changes the CTA to Get Started and tells the user to try again later from the VO2+ tab.

Strengths:

- Health permission is requested in context after the welcome step, rather than on an unexplained first launch.
- Profile and target personalization create a reason to continue.
- The trial page describes the free baseline before presenting paid context.
- Restore is visible.
- The fallback keeps the core app usable when offerings fail.
- The app does not write HealthKit data.

Findings:

1. The onboarding .task calls trackPaywallImpression with vo2plus_onboarding_trial as soon as onboarding appears. It does not wait until the trial step is visible. A user who quits on welcome, profile, or target can be counted as a paywall impression without seeing a paywall.
2. Onboarding buys the monthly package, while Settings direct conversion buys yearly and full PaywallView defaults yearly. This is a valid possible experiment, but the code does not show an explicit assignment or experiment ID.
3. StoreService.purchase returns purchased, cancelled, or pending, but OnboardingView ignores the return value. It relies only on a later isPro change.
4. The fallback state is difficult to reach as a paywall fallback because the normal CTA becomes Get Started when monthlyPackage is nil. The startTrial guard that sets showPaywallFallback is therefore not the primary user path.
5. A HealthKit authorization prompt error is treated as nonfatal and the user advances. That is appropriate for a local-first free app, but the next screen needs an explicit connected, not connected, no sample, and retry state.
6. A default reference age of 35 can make the target feel personalized before the user has supplied a value. The copy should make clear that the value is a starting reference, not a medical or individualized assessment.
7. The trial CTA is “Continue with VO2+”, which is neutral and compliant, but it may hide the immediate billing and trial consequence. The billed amount and renewal disclosure should remain adjacent to the action in every state.

### Trial flow recommendations

P0:

- Define whether onboarding is the control monthly flow or whether yearly should be the control. If monthly is intentional, make Settings and focused paywalls explicit variants rather than silently diverging.
- Render pending as “Purchase pending” with a restore or check-again action. Do not finish onboarding or dismiss a trial offer until the entitlement is actually active.
- Add an offering-unavailable retry action directly on the onboarding screen. Keep free entry available.
- Move the onboarding impression to the trial step's first visible appearance, dedupe it once per onboarding session, and attach the exact entry and selected package.

P1:

- Add a visible plan selector or a clearly explained default, then test monthly and yearly ordering. Do not label a yearly plan as a trial if the user cannot see the same trial eligibility and renewal terms before purchase.
- Keep a stable free path for users who deny or postpone HealthKit permission.
- Add a no-sample success state after authorization with a concrete next step: record a qualifying outdoor walk, run, or hike and return to refresh.
- Add retry and offline copy for offering load failure, purchase failure, restore failure, and transaction pending.

## RevenueCat and purchase implementation audit

### Local implementation

Observed in Shared/Services/StoreService.swift:

- RevenueCat is configured only on a real device. Simulator execution returns before configuring the production SDK.
- The public SDK key is prefixed appl_. No secret key was found in the inspected app source.
- Debug -DemoPro is a local override.
- The cached isPro value is stored in the App Group for widgets and background work.
- Product mapping uses package type and product identifier fallback.
- purchase returns a PurchaseState that distinguishes purchased, cancelled, and pending.
- restorePurchases updates customer information and reports an error message on failure.
- trackPaywallImpression calls RevenueCat's custom paywall impression API.
- update(customerInfo:) sets isPro when any active entitlement exists. It does not check the declared proEntitlement constant.
- Intro offer eligibility is asynchronously resolved.

Risks:

- Unlocking on any active entitlement can unlock VO2+ if an unrelated entitlement is later added to the same RevenueCat project or customer. Check the exact configured entitlement identifier.
- The code constant is pro, while the RevenueCat UI label is V02 Max Pro. The UI label is not sufficient evidence of the REST identifier. Verify the identifier through the RevenueCat API or dashboard details.
- The local lifetime product is non-consumable while RevenueCat models it as non-renewing subscription. Resolve before relying on lifetime transaction history, entitlement expiration, or experiment metrics.
- Package ordering and trial copy are handled by custom SwiftUI code. The RevenueCat dashboard currently has no Paywall attached, so dashboard Paywall behavior is not the current user experience.
- The monthly product page was Loading in the captured RevenueCat state. Verify product approval, offering availability, and sandbox fetch behavior.

### RevenueCat custom attributes and funnel fields

No RevenueCat custom attribute setters or equivalent custom funnel fields were found in the inspected source. The app has custom paywall impression calls but no complete source attribution model.

Add only coarse, non-sensitive attributes if RevenueCat attributes are appropriate for the product. Do not send raw VO2 max values, RHR, HRR, workout samples, health records, exact age, or reference sex merely to analyze conversion.

Recommended fields:

| Field | Values | Insertion point | Purpose |
| --- | --- | --- | --- |
| app_version_build | release string | StoreService.configureIfNeeded or app startup | Segment regressions by shipped build |
| funnel_entry | onboarding, plus_tab, settings, locked_feature, whats_new | Before presenting a purchase surface | Compare conversion by entry |
| paywall_focus | none, deep_trends, target_projection, fitness_age_context, alerts, recap, report, other | PaywallView and TrialOfferSheet presentation | Identify the feature that creates intent |
| selected_package | monthly, yearly, lifetime | Plan selection and purchase start | Explain plan mix |
| trial_eligibility | eligible, ineligible, unknown | After intro eligibility resolves | Avoid mixing unavailable trials with trial cohorts |
| store_load_state | loading, loaded, error, empty | Offering load completion or failure | Detect catalog and network failures |
| purchase_result | purchased, cancelled, pending, failed | StoreService.purchase completion | Find user-visible transaction failures |
| onboarding_step | welcome, profile, target, trial, completed | On step transition | Find activation drop-off |
| health_flow_state | not_prompted, prompt_completed, no_sample, reading_available, access_error, refresh_error | HealthKit state transitions | Separate permission friction from product value |
| reading_count_bucket | none, one, two_to_four, five_plus | After a read, without sending values | Segment value discovery by data availability |
| watch_capable | yes, no | App startup | Compare phone-only and watch users |
| widget_present | yes, no | App startup or local capability check | Diagnose widget freshness and conversion |

RevenueCat attributes are not a substitute for event analytics. RevenueCat's transaction lifecycle should remain the source for purchase and renewal facts. Paywall impressions should use stable, visible-surface IDs. If additional funnel events are needed, use a local structured log or an approved analytics system with a documented retention policy. Do not add a new tracking system just to solve a naming problem.

Recommended stable impression IDs:

- vo2plus_onboarding_trial_monthly.
- vo2plus_tab_default.
- vo2plus_settings_locked_feature_<feature>.
- vo2plus_settings_trial_offer_yearly.
- vo2plus_whats_new.

The feature suffix should come from a fixed allowlist, not arbitrary user text.

### Purchase state machine

The implementation agent should model this explicitly:

1. Offering loading.
2. Offering loaded.
3. Offering unavailable.
4. Eligibility unknown.
5. Eligible.
6. Ineligible.
7. Purchase in progress.
8. Purchased and entitlement active.
9. Pending and entitlement not active.
10. Cancelled by user.
11. Failed with recoverable error.
12. Restoring.
13. Restored and entitlement active.
14. Restore failed.

The UI should never infer success from the purchase call returning if customer information does not show the expected entitlement. Pending is not success.

## Paywall audit and A/B opportunities

### Current custom paywall structure

Observed:

- PaywallView is a custom SwiftUI paywall.
- The VO2+ tab passes a custom impression ID, vo2plus_tab.
- PaywallView defaults to vo2plus_paywall for other instances.
- PaywallView defaults the selected package to yearly.
- Focused paywalls use feature-specific content but generally inherit the same default impression ID.
- TrialOfferSheet is used by Settings for a direct yearly purchase and does not call trackPaywallImpression.
- Onboarding uses a separate trial surface and selects monthly.
- PaywallView has loading, empty, retry, restore, terms, privacy, purchase, and error affordances.
- Reduce Motion suppresses the SparkleField effect in TrialOfferSheet.

Measurement gap:

The app can identify that a general paywall was seen, but it cannot reliably answer which entry point, feature focus, selected product, eligibility state, and purchase result produced the transaction. Fix attribution before choosing a winning variant.

### Native RevenueCat Paywall status

RevenueCat currently shows no Paywall and no Experiment attached to the default offering. Therefore, a RevenueCat native Paywall A/B test is not currently running. The current experience is custom SwiftUI.

After the product catalog is corrected, possible native Paywall dimensions include:

- Offering and package order.
- Monthly-first versus yearly-first.
- Whether the lifetime option is an anchor or a secondary choice.
- Trial label visibility for eligible and ineligible users.
- Per-month equivalent price display.
- Feature list ordering.
- Focused feature message versus broad VO2+ message.
- Restore location and prominence.
- Retry behavior when offerings are unavailable.
- Intro offer presentation and renewal disclosure.
- Paywall template versus custom SwiftUI parity.

Any native Paywall experiment must preserve Apple billing, renewal, cancellation, trial eligibility, and price disclosures. It must also be compared with the custom SwiftUI path, not mixed into the same unlabeled impression ID.

### Recommended experiments

| Priority | Hypothesis | Variants | Primary metric | Secondary metrics | Guardrails |
| --- | --- | --- | --- | --- | --- |
| P1 | A consistent default plan reduces confusion | Monthly-first versus yearly-first | Trial start rate | Purchase completion, trial-to-paid, refund, cancellation | No increase in pending or restore failures |
| P1 | A feature-specific paywall improves intent | Focused target, trend, or context paywall versus generic VO2+ | Paywall-to-purchase | Dismissal, repeat opens, support contacts | Keep free baseline clear |
| P1 | Timing affects trial quality | Trial during onboarding versus after first reading | Qualified trial start, defined as active entitlement after purchase | First-week retention, first renewal | Do not block free use or Health permission |
| P1 | Eligibility-aware copy reduces false expectations | Eligible trial copy versus ineligible non-trial copy | Purchase completion | Cancellation within seven days, support requests | Exact billing and renewal disclosure |
| P1 | Stable attribution identifies the best entry | Onboarding, tab, Settings, locked feature, What's New | Trial start by entry | Revenue and retention by entry | Same catalog and pricing |
| P2 | The lifetime anchor improves revenue without hurting trial starts | Lifetime visible versus secondary placement | Net revenue per eligible visitor | Subscription mix, refund, restore | Product type must be fixed first |
| P2 | Free feature matrix clarity improves trust | Current copy versus explicit free number and paid context copy | Trial start and review sentiment | Onboarding completion, support | No overclaiming |
| P2 | Retry reduces offering-load abandonment | Static free fallback versus retry plus status detail | Return to paywall and eventual purchase | Error rate, session length | Keep user unblocked |

Use stable assignment at the user or install level. Store the assignment separately from the health data model. Do not use raw HealthKit values as experiment eligibility.

## Ratings and review funnel

### Current funnel

Observed in Shared/Services/ReviewPromptTracker.swift, VO2Max/App.swift, ReviewPromptSheet.swift, and AppStoreReviewLinks.swift:

- Positive eligibility requires at least three launches, at least three days, and one positive moment.
- Engaged eligibility requires at least five launches, at least seven days, and at least one reading.
- A positive moment is associated with a new personal best or entering the target range after an established prior reading.
- There is a 120-day hard cooldown and a 30-day soft defer.
- The user can choose the App Store review path, feedback path, or Maybe later.
- The explicit review URL uses App Store ID 6791235742 and storefront-aware country handling with a fallback.
- The Maybe later path records a soft defer and then requests the system review prompt on dismiss.
- Feedback uses a mailto address with a +vo2 alias.
- The public listing has insufficient ratings to display an overview.

Strengths:

- The prompt is delayed until the user has evidence of value.
- There is a feedback branch before asking the user to post a review.
- There is a cooldown.
- New personal best and target-entry moments are product-relevant triggers.
- The explicit App Store link is more dependable than relying only on the system prompt.

Risks:

- The exact number of prompt presentations, explicit review-link opens, mail opens, system prompt requests, and outcomes is not exposed in the inspected funnel data.
- The system prompt can no-op, so the implementation agent should not treat requestReview as a completed review.
- The storefront URL mapping should be tested with a storefront country code, a Locale fallback, and no region.
- The feedback alias differs from the support alias. Verify delivery.
- Never present the rating prompt during Health permission, purchase, restore, error, or first-run flows.

Recommended review instrumentation:

- review_candidate_eligible with eligibility reason.
- review_prompt_presented.
- review_app_store_link_opened.
- review_feedback_link_opened.
- review_soft_deferred.
- review_system_request_invoked.
- review_outcome_local_only, with no review text or rating value.

If these are stored locally, keep only counters and timestamps in the App Group. Do not send health values.

## Onboarding and general UX

### Dashboard and feature entitlement

Observed in DashboardView.swift:

- The latest estimate, trend, fitness age card, and target-related UI are available on the dashboard.
- The no-reading state explains that a qualifying outdoor walk, run, or hike may be needed and provides Apple Health actions.
- Dashboard refresh is available.
- Fitness age is not gated by store.isPro in fitnessAgeCard.

Observed in PlusTabView.swift and DetailViews.swift:

- Free users see locked teasers and an embedded paywall only while the VO2+ tab is active.
- Pro users see the hub and supporting context.
- Target projection is gated.
- Fitness age detail shows a basic value before gating broader context or band information.
- Subscriber context loads when the Plus tab is visited.

Potential UX improvement:

Make the free versus paid boundary visible at the exact point of value. For example, label the free fitness age number as a basic estimate and label the paid context as additional interpretation or trend context. Avoid wording that implies medical interpretation.

### Empty, failure, and retry states

Observed:

- Onboarding has a free fallback when the offering is unavailable.
- PaywallView has a purchase-unavailable state and Try Again.
- Settings offers restore and Apple Health refresh.
- HealthKit refresh errors are held in lastError.
- StoreService stores an errorMessage.

Validate:

- Whether every errorMessage is rendered near the action that caused it.
- Whether an offering error preserves a previously loaded package or replaces the full screen with an empty state.
- Whether a pending purchase survives app relaunch and has an understandable path to re-check.
- Whether restore with no purchases has a neutral completion message.
- Whether a revoked Health permission differentiates access denied from no data.
- Whether offline launch can show cached data without an offering error covering the free app.

### Accessibility and visual UX

Observed:

- The previous .claude handoff says hidden tabs were removed from the accessibility tree and paywall impression inflation from an always-alive tab was fixed.
- The same handoff lists large Dynamic Type x-axis truncation, light-mode tab bar material collision, and incomplete dark appearance verification as remaining work.
- The public App Store listing did not indicate developer-supported accessibility features.
- TrialOfferSheet avoids the sparkle effect when Reduce Motion is enabled.
- The contact sheet shows a coherent dark teal visual language and clear screenshots.

Required test matrix:

- VoiceOver through welcome, Health permission explanation, target editing, trial, paywall, restore, error, and review prompt.
- Dynamic Type through the largest supported sizes, especially trend x-axis labels, plan cards, disclosures, and target controls.
- Light and dark appearance.
- Reduce Motion.
- Bold Text and increased contrast where supported.
- iPhone compact and large layouts.
- Watch small and large display sizes.
- Right-to-left locale for metadata and layout where applicable.

Only declare accessibility features in ASC after the runtime test confirms them.

## HealthKit, background delivery, widgets, and watch

### iOS observer rules

Observed in Shared/Services/HealthKitService.swift:

- HealthKitService is a MainActor service.
- It reads HKQuantityType.vo2Max in mL/kg/min.
- App.init calls enableBackgroundDelivery before the scene task.
- enableBackgroundDelivery is gated by a persisted App Group authorization flag and HealthKit availability.
- The observer query executes its HealthKit completion handler immediately, then schedules refreshCache.
- Background delivery is requested with daily frequency.
- refreshCache reads up to 365 days, updates SwiftData, handles new readings, and reloads all WidgetKit timelines.
- Empty HealthKit reads preserve the cache to avoid treating denied access or a temporary empty response as deletion.
- New readings can trigger a review-positive moment and an optional local notification.

This App.init placement is important. A background HealthKit relaunch may not connect a scene, so observer setup cannot depend only on a scene .task. The current iOS code follows that rule.

### Watch observer question

Observed in VO2MaxWatch/App.swift:

- The watch app defines a WindowGroup with WatchTodayView and a model container.
- It does not call HealthKitService.enableBackgroundDelivery in an App.init.
- WatchTodayView calls synchronizeAuthorization from a .task.
- The watch reads the shared CardioFitnessSample model and prompts for a qualifying walk, run, or hike when there is no data.

Inference:

The watch may not need to own the same observer if the phone is the sole writer to the App Group cache, but this is not established by the repository. If the watch complication or watch app is expected to refresh independently, the current scene-task-only path is a potential stale-data bug.

Required validation:

1. Authorize on phone and watch.
2. Create or import a new VO2 max sample while the phone app is not open.
3. Keep the phone app terminated and wait for HealthKit background delivery.
4. Check the phone App Group cache, widget timeline, watch app, and watch complication.
5. Cold launch the phone and compare the result.
6. Repeat with the phone process force-terminated before the sample.
7. Repeat with permission revoked, no sample, and a refresh error.

If the watch must refresh independently, define whether Watch App.init should install an observer or whether watch connectivity should receive the authoritative cache. Do not add duplicate observers without measuring battery impact.

### Context data gap

Observed in Shared/Services/CardioContextService.swift:

- The service reads resting heart rate, heart rate recovery, and workouts.
- It keeps arrays in memory.
- It loads up to 730 days.
- It throttles to one load per minute.
- It requests context authorization lazily.
- It has no background observer or persistent context cache.
- PlusTabView loads context when a subscriber visits the Plus tab.

Inference:

A new RHR, HRR, or workout sample can be available in HealthKit while a visible VO2+ screen still shows old context until the user visits or refreshes. If the product promise is “current context”, add a freshness timestamp and a deliberate refresh policy. If on-demand is intended, label the refresh behavior.

Do not read or transmit more health data than the feature needs. Keep health values local and use only coarse health-flow states for conversion analysis.

### Persistence and widget risk

Observed in Shared/Services/DataService.swift:

- SwiftData uses App Group group.com.jackwallner.vo2max.
- The store name is VO2Max.store.
- CloudKit is not configured.
- If the persistent store cannot initialize, the service falls back to an in-memory store and logs the error.
- Widgets and watch widgets read the App Group model.
- Widget timelines are scheduled roughly every six hours.
- A new VO2 max reading reloads WidgetKit timelines.
- The no-data widget tells the user to open the app to sync.

P1 concern:

An in-memory fallback can make cached history disappear after process termination and can leave widgets empty. The user needs a visible recovery path and a diagnostic record that distinguishes a store failure from no Health data.

Validate:

- Store initialization failure and restart.
- App Group permission or migration failure.
- New background sample followed by widget reload.
- Widget timeline timestamp and value after a background update.
- Watch widget behavior when the phone has not been opened.

## Health and compliance review

Observed:

- ASC readiness checks include health and wellness rating and no medical or treatment information.
- App description, onboarding, dashboard, support, and terms use fitness, trend, target, estimate, and local processing language.
- The repository README explicitly avoids diagnosis, treatment, and prediction claims.
- Terms include a fitness disclaimer.
- The app reads HealthKit and does not write HealthKit data.
- The privacy policy describes local Health data processing.

Keep:

- Apple Health VO2 max estimate.
- Cardio fitness trend.
- Fitness age as a broad fitness estimate, with an explanation of its limitations.
- Personal target range as a user-configurable fitness reference.
- Guidance framed as informational or fitness-oriented.

Avoid:

- Diagnose, treat, cure, prevent, or detect disease claims.
- Clinical accuracy claims.
- Longevity or mortality prediction claims.
- Claims that a target or score is appropriate for every user.
- Copy that implies the app replaces a clinician or medical device.

Required validation:

- Search all ASC locales, website pages, screenshots, terms, onboarding copy, notification copy, and review notes for prohibited or overstrong claims.
- Check that the fitness-age label is explained as an estimate.
- Confirm the App Store age and health rating are still correct for the current feature set.
- Keep notification copy fitness-oriented and avoid implying that a single reading is an urgent health event.

## Crash, regression, and watchdog audit

### Current evidence

No repository evidence was found for a live-user crash monitor, MetricKit subscriber, Crashlytics integration, ASC crash export, or a watchdog script for this app. No live crash spike can be confirmed or excluded from this audit.

The existing local evidence includes:

- ios27VO2Max.md, dated 2026-08-05, reporting a prior debug build, unit tests, rebuild, install, launch, and UI snapshot pass.
- .claude/HANDOFF-vo2plus-audit.md, dated 2026-08-02, reporting earlier accessibility and paywall impression checks plus remaining verification gaps.
- VO2MaxTests covering analysis, range, freshness, review eligibility, and conversion copy.

The historical test counts differ between documents, with one document reporting 65 tests and another 72. Treat both as historical until a current headless test run records the exact test command, scheme, destination, and count.

### Signals to collect per release

For each public build and TestFlight build, collect:

- Crash-free users and sessions.
- Crash rate by app version, build, iOS version, device family, and country.
- Hang rate and launch failure rate.
- Termination during onboarding, Health permission, offering load, purchase, and restore.
- RevenueCat offering-load failure count.
- Purchase pending count and age.
- Purchase failure count by product and error category.
- Restore failure count.
- HealthKit observer refresh age.
- Last successful HealthKit cache write age.
- Last widget timeline reload age.
- Watch data freshness age.
- SwiftData store fallback count.
- Review link open and feedback link open counts, if local telemetry is approved.
- Trial start, trial conversion, refund, cancellation, and renewal from RevenueCat.

### Suggested release alert rules

These are starting thresholds for a configurable script, not deployed notifications:

- Alert when a new build has a statistically meaningful crash-free-user drop against the previous stable build.
- Alert when crash or hang rate is elevated for two consecutive observation windows after release.
- Alert when offering load errors or purchase failures increase by a fixed absolute threshold and a relative multiple.
- Alert when pending purchases remain unresolved beyond a configured age.
- Alert when no successful HealthKit cache write occurs for a configured period in a user cohort that has previously read data.
- Alert when widget or watch freshness exceeds the expected interval.
- Alert when the App Store version, repository project version, ASC state file, or release notes disagree.
- Alert when any product identifier, price, subscription group, product type, entitlement, or trial duration differs among StoreKit, ASC, and RevenueCat.
- Alert when terms, privacy, support, or marketing URLs fail or change content unexpectedly.

The implementation agent can build the non-AI portion as a scheduled Mac script that reads ASC exports or API responses, RevenueCat exports or API responses, local metadata, site HTML, and approved crash exports. It should emit JSON and a human-readable report, then optionally invoke a user-configured email command. It should not attempt to infer a root cause from raw logs.

### Regression scenarios

Run after every release that changes app code, HealthKit code, purchase code, widget code, or shared services:

- Fresh install with no HealthKit data.
- HealthKit allow, deny, revoke, and limited or unavailable states.
- First sample, second sample, personal best, target entry, and stale data.
- Background sample with phone app terminated.
- Widget reload after background sample.
- Watch app and watch widget with phone closed.
- Offering load success, empty, timeout, offline, and retry.
- Monthly, yearly, and lifetime purchase in StoreKit test or sandbox.
- Eligible trial, ineligible user, cancelled purchase, pending purchase, failed purchase, restore success, restore empty, and restore failure.
- Free user opening every locked feature from Dashboard, Plus tab, Settings, and What's New.
- Review eligibility below and above thresholds.
- VoiceOver, largest supported Dynamic Type, Reduce Motion, dark mode, light mode, and watch layouts.

## Cursor, Claude, and Codex documentation contract

### Observed conflict

AGENTS.md and CLAUDE.md are separate regular files, not symlinks.

AGENTS.md:

- Describes the project as local-first.
- Names the XcodeGen scheme VO2Max.
- Uses simulator wording around agent-vo2max.
- Contains shared app and RevenueCat guidance.
- Does not contain the critical background observer rule found in CLAUDE.md.

CLAUDE.md:

- Describes the same project and targets.
- Uses simulator wording around sim lease owner vo2max.
- States that the HealthKit observer must be re-executed from App.init rather than a scene .task.
- Documents the historical bug where background HealthKit relaunches did not connect a scene and widgets stayed stale.
- Identifies HealthKitService.enableBackgroundDelivery as the idempotent entry point gated by persisted authorization.

Other documentation:

- No .cursor, .codex, or .agents directory was found in the app repository.
- .claude exists and contains a stale handoff and a verify skill.
- README.md uses agent-sim boot vo2max.
- .claude/skills/verify/SKILL.md uses a dedicated agent-vo2max simulator and agent-sim boot vo2max.
- The current shared convention is a ten-device pool with agent-sim checkout vo2max, a returned UDID, and agent-sim checkin vo2max.

Risk:

An agent following AGENTS.md, CLAUDE.md, README.md, or the old verify skill can select a different simulator, use a named device, or move observer setup back into a scene task. This is exactly the sort of cross-agent drift that can reintroduce a production freshness bug.

### Recommended canonical contract

Use one canonical app-level document for all three agents. A practical contract is:

1. Make CLAUDE.md the canonical app-specific document only if that is the chosen convention for this repository.
2. Make AGENTS.md a symlink to the canonical document, or generate it from the same source if the tooling requires a regular file.
3. Keep Cursor-specific instructions in the same canonical document or a clearly named section. Do not maintain a second independent truth.
4. Define the app slug as vo2max.
5. Define the simulator lease command as agent-sim checkout vo2max.
6. Always target the returned UDID with destination id=<UDID>.
7. Release the lease with agent-sim checkin vo2max.
8. Prohibit name-based destinations and opening Simulator.app.
9. State that the iOS observer is installed from App.init and remains idempotent.
10. State that the watch behavior must be separately validated and must not be assumed to inherit the iOS observer.
11. Put the current release and verification recipe in the canonical document, then archive older handoffs.

Do not silently delete historical evidence. Move stale audit and handoff material into an explicitly historical directory such as docs/audits/ or docs/archive/handoffs/ and add a short pointer from the canonical document. The implementation agent must perform any move only after confirming no automation depends on the old path.

### Stale documents to classify

- ios27VO2Max.md: historical audit dated 2026-08-05. Move under a dated audits directory or label it clearly as historical.
- .claude/HANDOFF-vo2plus-audit.md: historical handoff dated 2026-08-02. Archive it after extracting any still-valid verification requirements.
- .claude/skills/verify/SKILL.md: update the simulator and background observer rules or replace it with a pointer to the canonical contract.
- README.md: update the simulator command and current product/release facts.
- docs/astro-aso-setup.md: compare its recommended subtitle and ASO assumptions with current metadata before agents use it.

## Prioritized implementation backlog

### P0, before the next paid release

1. Reconcile product catalog

   Evidence: StoreKit lifetime is non-consumable at 59.99 USD, ASC setup code contains 29.99 USD, and RevenueCat shows lifetime as non-renewing subscription.

   Change locus: VO2Max.storekit, RevenueCat catalog, ASC setup/readiness scripts, product copy, and review notes.

   Done when: product ID, type, price, subscription group, entitlement, trial, restore behavior, and copy agree in all systems and a purchase matrix passes.

2. Make entitlement checking explicit

   Evidence: StoreService.update enables isPro when any active entitlement exists; the declared proEntitlement constant is not used for the check.

   Change locus: StoreService.update and RevenueCat project configuration.

   Done when: only the intended entitlement unlocks VO2+, and a test entitlement or unrelated active entitlement cannot unlock the app.

3. Make pending purchases safe

   Evidence: StoreService can return pending, OnboardingView ignores the result, Settings treats pending like purchased, and PaywallView has no pending state.

   Change locus: StoreService, OnboardingView, SettingsView, TrialOfferSheet, and PaywallView.

   Done when: pending never completes onboarding or dismisses a trial sheet as success, and the user can re-check or restore.

4. Validate background HealthKit freshness

   Evidence: iOS App.init installs the observer, watch App.swift does not, and only VO2 max has an observer.

   Change locus: runtime validation first, then watch or shared service design only if the test shows a gap.

   Done when: the supported phone, widget, watch, and cold relaunch behavior is proven with timestamps.

5. Canonicalize agent docs and simulator names

   Evidence: separate AGENTS.md and CLAUDE.md conflict, README and verify skill use older simulator language.

   Change locus: AGENTS.md, CLAUDE.md, README.md, .claude/skills/verify/SKILL.md, and archive pointers.

   Done when: all three agent types get the same observer rule, checkout recipe, no-named-destination rule, and release verification guidance.

### P1, before interpreting funnel experiments

6. Fix impression placement and IDs

   Evidence: onboarding impression is recorded before the trial step, focused PaywallView surfaces share the default ID, and TrialOfferSheet has no impression.

   Change locus: OnboardingView, PaywallView, SettingsView, TrialOfferSheet, and StoreService.

   Done when: every impression is visible-surface, once per intended session, and attributed to entry, focus, selected package, and eligibility.

7. Choose and label monthly versus yearly strategy

   Evidence: onboarding is monthly, Settings is yearly, full PaywallView defaults yearly.

   Change locus: product decision plus onboarding, Settings, paywall copy, and experiment assignment.

   Done when: the control experience is documented and variants can be compared without confounding.

8. Publish a single entitlement matrix

   Evidence: site labels fitness age and target range as VO2+, while the app exposes basic versions free.

   Change locus: DashboardView, detail views, OnboardingView, PlusTabView, docs/index.html, screenshots, ASC metadata, terms, and review notes.

   Done when: a reviewer can predict exactly what a free user sees and what VO2+ adds.

9. Add coarse funnel attributes

   Evidence: no custom attributes or complete entry attribution found.

   Change locus: StoreService startup and purchase lifecycle, paywall presentation, onboarding step transitions, Settings entry points.

   Done when: the team can report trial starts and purchase outcomes by entry and package without raw health data.

10. Add context freshness or disclose on-demand behavior

   Evidence: CardioContextService is in-memory, foreground-loaded, and has no background observer.

   Change locus: CardioContextService and PlusTabView, only after choosing the battery and privacy boundary.

   Done when: a subscriber sees a timestamp or a clear refresh action and the data is not silently stale.

11. Reconcile localization and canonical site

   Evidence: 50 local locale directories versus public English-only appearance, and GitHub Pages versus jackwallner.com canonical URLs.

   Change locus: fastlane metadata, ASC localization state, docs site, workflow, and metadata URLs.

   Done when: the repository and public listing describe the same live localization and site source.

### P2, conversion and polish

12. Improve screenshot and metadata learning

   Test first screenshot Apple Health and VO2 max intent, broader versus athlete framing, and explicit free versus paid value. Keep the same binary and catalog for clean comparison.

13. Complete accessibility QA and ASC declaration

   Recheck VoiceOver, Dynamic Type, dark and light appearance, Reduce Motion, and watch layouts. Declare only verified support.

14. Increase review funnel reliability

   Keep the positive moment logic, verify support and feedback delivery, instrument local outcomes, and do not ask during purchase or permission flows.

15. Add the non-AI watchdog

   Build the release consistency, product catalog, website, crash export, RevenueCat, HealthKit freshness, and widget freshness checks described in this audit. Keep email notification configuration disabled by default until the user enables it.

## Validation plan for the implementation agent

### Static checks

Run from /Users/jackwallner/health:

    python3 scripts/validate-metadata.py

Run the read-only ASC readiness check with the existing credential mechanism, after confirming it does not call a mutation endpoint. Record app ID, draft version, build, locale count, screenshot count, product statuses, and URL checks.

Search for drift:

    rg -n "1\\.0\\.0|1\\.1\\.0|1\\.1\\.1|1\\.1\\.2|build 35|build 43|29\\.99|59\\.99|yearly|monthly|agent-vo2max|agent-sim boot|enableBackgroundDelivery|trackPaywallImpression" .

The result should be reviewed, not blindly replaced. Historical audit files should be excluded from current release assertions or moved to an archive.

### Headless simulator recipe

Use the shared pool. Do not use a named destination and do not open Simulator.app:

    LEASE=$(agent-sim checkout vo2max)
    UDID=$(printf '%s\n' "$LEASE" | tail -1)
    xcodegen generate
    xcodebuild -project VO2Max.xcodeproj -scheme VO2Max -destination "id=$UDID" -derivedDataPath /tmp/vo2max-verify build
    xcodebuild test -project VO2Max.xcodeproj -scheme VO2Max -destination "id=$UDID" -derivedDataPath /tmp/vo2max-verify
    agent-sim checkin vo2max

Use a trap in the real script so a failed build returns the lease. Never configure the production appl_ RevenueCat key on a simulator. Use the local StoreKit configuration and the repository's demo flags for simulator purchase tests.

Record:

- Exact command.
- Xcode version.
- OS version.
- Simulator UDID.
- Test count.
- Build result.
- Screenshot or accessibility evidence.
- Whether the test used demo data, local StoreKit, or a real device.

### Runtime purchase matrix

| Scenario | Expected result |
| --- | --- |
| Monthly eligible | Trial disclosure, purchase, active pro entitlement, onboarding completion only after entitlement |
| Monthly ineligible | No false trial promise, correct price and renewal disclosure |
| Yearly eligible | Same explicit trial rules as monthly, with yearly price |
| Lifetime | One-time purchase and non-renewing behavior only after catalog type is corrected |
| User cancellation | Paywall remains usable, no error pretending to be a failed purchase |
| Pending | Visible pending state, no onboarding completion, re-check or restore path |
| Offering unavailable | Free app remains usable, retry action, no misleading trial CTA |
| Purchase failure | Recoverable error, selected plan retained, retry |
| Restore with purchase | Entitlement becomes active and all paid surfaces update |
| Restore without purchase | Neutral no-purchases message and free app remains usable |
| Revoke or expire entitlement | Paid surfaces lock safely and cached state is refreshed |

### HealthKit and UX matrix

| Scenario | Expected result |
| --- | --- |
| First launch | Clear value explanation and contextual permission request |
| Permission denied | Free path remains usable and explains how to reconnect |
| Permission revoked | UI distinguishes revoked access from no sample |
| No sample | Concrete qualifying activity guidance, no medical implication |
| First sample | Cache, dashboard, widget, review eligibility, and notification behavior are correct |
| Background sample | Observer refreshes without a scene connection |
| Watch sample or watch read | Watch and phone freshness behavior is documented and verified |
| New personal best | Review moment only after thresholds and not during a blocking flow |
| Target entry | Same review guardrails |
| RHR, HRR, workout changed | Context freshness is updated or visibly marked as on-demand |
| Store fallback | User sees a recovery path and data-loss risk is logged |

## Evidence index

Local project and release:

- project.yml
- VO2Max.storekit
- scripts/.asc-state.json
- scripts/.astro-app.json
- scripts/asc-readiness.py
- scripts/asc-setup-release.py
- fastlane/metadata/en-US
- fastlane/metadata/review_information/notes.txt
- README.md

App flow:

- VO2Max/App.swift
- VO2Max/Views/OnboardingView.swift
- VO2Max/Views/PaywallView.swift
- VO2Max/Views/TrialOfferSheet.swift
- VO2Max/Views/SettingsView.swift
- VO2Max/Views/PlusTabView.swift
- VO2Max/Views/DashboardView.swift
- VO2Max/Views/DetailViews.swift
- VO2Max/Views/ReviewPromptSheet.swift

Shared services:

- Shared/Services/StoreService.swift
- Shared/Services/HealthKitService.swift
- Shared/Services/CardioContextService.swift
- Shared/Services/DataService.swift
- Shared/Services/ReviewPromptTracker.swift
- Shared/Services/NotificationService.swift
- Shared/Utilities/VO2ConversionCopy.swift
- Shared/Utilities/AppStoreReviewLinks.swift

Watch and widget:

- VO2MaxWatch/App.swift
- VO2MaxWatch/Views/WatchTodayView.swift
- widget target sources in VO2MaxWidget and VO2MaxWatchWidget

Site and legal:

- docs/index.html
- docs/support.html
- docs/terms.html
- docs/privacy-policy.html
- .github/workflows/sync-landing-page.yml

Agent documentation:

- AGENTS.md
- CLAUDE.md
- .claude/skills/verify/SKILL.md
- .claude/HANDOFF-vo2plus-audit.md
- ios27VO2Max.md

## Completion criteria

This audit is complete when:

- /Users/jackwallner/health/audit823.md exists.
- The audit covers local source, config, ASC and public listing evidence, RevenueCat, trial and purchase flow, review funnel, onboarding, paywalls and experiments, website and legal consistency, HealthKit background behavior, release watchdog signals, compliance, and agent documentation.
- Findings distinguish observed evidence, inference, and validation work.
- Every high-priority item has a path, symbol or surface, rationale, and validation step.
- No file other than audit823.md is changed.
- No commit or push is performed.

## Activity and success context, 2026-08-23

Classification: **active monetizing**. Confidence: **high**. Trend: **no ASC comparison displayed**.

ASC release state: `iOS 1.1.1 Ready for Distribution`. ASC evidence: [Analytics Overview](https://appstoreconnect.apple.com/apps/6791235742/analytics/overview?dateSpec=d90), selected range `dateSpec=d90`.
RevenueCat evidence: [Project Overview](https://app.revenuecat.com/projects/9ca6f38c/overview), production mode, selected range `Last 28 days, 2026-07-27 through 2026-08-23`.

### Observed activity

| Source | Metric | Value | Window or comparison |
| --- | --- | ---: | --- |
| ASC | First-time downloads | 47 | 90-day Analytics Overview |
| ASC | Redownloads | 8 | 90-day Analytics Overview |
| ASC | Conversion rate | 1.79% | comparison not displayed |
| ASC | Proceeds | $38 | 90-day Analytics Overview |
| ASC | In-app purchases | 9 | 90-day Analytics Overview |
| RevenueCat | New customers | 61 | last 28 days |
| RevenueCat | Active customers | 83 | last 28 days |
| RevenueCat | Active trials | 1 | current total |
| RevenueCat | Active subscriptions | 3 | current total |
| RevenueCat | MRR | $4 | current total |
| RevenueCat | Revenue | $45 | last 28 days |

A missing value above means the source did not expose that metric in this read-only snapshot. It is not a zero.

### Interpretation and implementation focus

VO2 is active but low scale: 47 ASC first-time downloads, $38 ASC proceeds, 61 RevenueCat new customers, 1 active trial, 3 active subscriptions, and $45 RevenueCat revenue. That is enough to prove a paid path exists, not enough to optimize aggressively. Verify HealthKit and first-result value, keep the non-diagnostic framing, and measure the path from first estimate to trial and renewal.

The deterministic classifier recommends: Protect the current paid path, then use release and cohort baselines to decide whether acquisition or conversion is the next constraint.

- Join ASC first-time download, first launch, first value, paywall shown, offer loaded, trial started, trial canceled, trial converted, entitlement active, restore, and purchase failure events with the app version and build.
- Keep ASC's 90-day acquisition and proceeds window separate from RevenueCat's 28-day customer and revenue window. Do not calculate a conversion rate by dividing values from different windows.
- Use a mature trial cohort and a minimum sample before choosing a native paywall or onboarding A/B winner. Record the offering identifier, package, placement, experiment variant, and build.
- Put the app's classification and the next baseline date in the release handoff so Cursor, Claude, and Codex do not optimize from an old qualitative audit.

### Boundary on success or death

This snapshot supports the label **active monetizing**, not a lifetime verdict. The app has current paid activity, but ASC does not expose a positive comparison for the selected window. A later decision should include a clean 28-day RevenueCat trend, ASC acquisition and conversion trend, ratings and review count, crash and hang evidence, and a release-specific cohort.
This dated section supersedes earlier statements in this file that per-app ASC or RevenueCat activity was unavailable as of 2026-08-23. Earlier statements remain historical evidence boundaries for their original audit pass.
