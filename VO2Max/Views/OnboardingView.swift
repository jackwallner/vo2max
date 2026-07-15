import SwiftUI

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject private var settings: GoalSettings
    @StateObject private var health = HealthKitService.shared
    @State private var isConnecting = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 84))
                    .foregroundStyle(Theme.cardioGradient)
                VStack(spacing: 10) {
                    Text("Your cardio fitness, at a glance")
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)
                    Text("See your latest Apple Health VO2 max estimate, understand the direction of your trend, and keep it visible on your Home Screen and Apple Watch.")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(alignment: .leading, spacing: 16) {
                    onboardingRow("waveform.path.ecg", "Focused", "One calm dashboard instead of a training platform")
                    onboardingRow("lock.shield", "Private", "Your fitness data stays on your devices")
                    onboardingRow("applewatch", "Glanceable", "Widgets and real Watch complications")
                }

                Spacer()
                if let errorMessage {
                    Text(errorMessage).font(.caption).foregroundStyle(Theme.negative)
                }
                Button {
                    isConnecting = true
                    Task {
                        do {
                            try await health.requestAuthorization()
                            settings.hasCompletedSetup = true
                            isPresented = false
                        } catch {
                            errorMessage = "Apple Health access could not be completed."
                        }
                        isConnecting = false
                    }
                } label: {
                    HStack {
                        if isConnecting { ProgressView().tint(.white) }
                        Text("Connect Apple Health").fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(Theme.cardio)
                .disabled(isConnecting)
                Text("VO2 max values are fitness estimates, not medical measurements. This app does not diagnose or treat health conditions.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(24)
        }
    }

    private func onboardingRow(_ symbol: String, _ title: String, _ detail: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.title2)
                .foregroundStyle(Theme.cardio)
                .frame(width: 34)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(detail).font(.subheadline).foregroundStyle(.secondary)
            }
        }
    }
}

