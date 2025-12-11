
import SwiftUI

struct SnackBarView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Snack Bar")
                .font(.title2.weight(.semibold))
            Text("Coming soon: a library of famous quotes to feed your collection.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
        }
        .padding(.bottom, 110)
    }
}
