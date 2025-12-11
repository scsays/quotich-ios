import SwiftUI

struct AccountView: View {
    @EnvironmentObject private var store: QuoteStore

    var body: some View {
        SettingsView(store: store)
            .padding(.bottom, 110)
    }
}

