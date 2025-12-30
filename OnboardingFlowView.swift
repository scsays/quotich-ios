import SwiftUI

struct OnboardingFlowView: View {
    var onFinish: () -> Void
    
    @State private var step: Int = 0
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    DesignSystem.monsterPurple.opacity(0.35),
                    DesignSystem.monsterPurple.opacity(0.18),
                    DesignSystem.lightPaper.opacity(0.92)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 18) {
                Spacer()
                
                Group {
                    switch step {
                    case 0:
                        OnboardingCard(
                            title: "Welcome to Memmi",
                            subtitle: "A tiny home for the lines that hit you in the chest.",
                            icon: "sparkles"
                        )
                    case 1:
                        OnboardingCard(
                            title: "Feed Memmi",
                            subtitle: "Save quotes from books, songs, podcasts, and life.\nMemmi stays full when you keep collecting.",
                            icon: "plus.circle.fill"
                        )
                    default:
                        OnboardingNotificationsCard()
                    }
                }
                .padding(.horizontal, 22)
                
                Spacer()
                
                HStack(spacing: 12) {
                    if step > 0 {
                        Button("Back") {
                            withAnimation(.easeOut(duration: 0.2)) { step -= 1 }
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Spacer()
                    
                    Button(step < 2 ? "Next" : "Get Started") {
                        if step < 2 {
                            withAnimation(.easeOut(duration: 0.2)) { step += 1 }
                        } else {
                            onFinish()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 26)
            }
        }
    }
    
    // MARK: - Reusable Card
    
    private struct OnboardingCard: View {
        let title: String
        let subtitle: String
        let icon: String
        
        var body: some View {
            VStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(DesignSystem.monsterPurple)
                
                Text(title)
                    .font(.title2.weight(.bold))
                    .multilineTextAlignment(.center)
                
                Text(subtitle)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }
            .padding(22)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        }
    }
    
    // MARK: - Notifications Screen (Step 3)
    
    private struct OnboardingNotificationsCard: View {
        @State private var statusText: String = "We’ll only nudge you when Memmi is hungry."
        
        var body: some View {
            VStack(spacing: 14) {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(DesignSystem.monsterPurple)
                
                Text("Notifications")
                    .font(.title2.weight(.bold))
                    .multilineTextAlignment(.center)
                
                Text("Memmi is at its best when full of your favorite quotes.\nAllow Memmi to notify you when it’s hungry?")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                
                Button("Enable Notifications") {
                    MemmiNotifications.shared.requestAuthorizationIfNeeded { granted in
                        DispatchQueue.main.async {
                            statusText = granted
                            ? "Nice. Memmi can now politely bother you."
                            : "No worries. You can enable this later in Settings."
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                
                Text(statusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 6)
            }
            .padding(22)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        }
    }
}
