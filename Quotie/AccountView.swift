import SwiftUI

struct AccountView: View {
    @EnvironmentObject private var store: QuoteStore
    @Environment(\.colorScheme) private var scheme

    @State private var showingSettings = false

    var body: some View {
        let bg = scheme == .dark ? DesignSystem.darkPaper : DesignSystem.lightPaper

        ZStack {
            bg.ignoresSafeArea()

            VStack(spacing: 16) {
                Text("Account")
                    .font(.title2.weight(.bold))

                Button("Settings") {
                    showingSettings = true
                }
                .buttonStyle(.borderedProminent)

                Spacer()
            }
            .padding(24)
        }
        .fullScreenCover(isPresented: $showingSettings) {
            SettingsView(store: store, onBack: { showingSettings = false })
        }
    }
}
