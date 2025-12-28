import SwiftUI

struct MemmiBubble: View {
    let text: String

    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            Image("memmi-avatar")
                .resizable()
                .frame(width: 48, height: 48)

            Text(text)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.secondarySystemBackground))
                )
        }
        .padding(.horizontal)
        .transition(.opacity)
    }
}

