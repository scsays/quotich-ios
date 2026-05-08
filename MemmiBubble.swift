import SwiftUI

struct MemmiBubble: View {
    let text: String

    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            Image("memmi-avatar")
                .resizable()
                .frame(width: 48, height: 48)

            Text(text)
                .font(.system(.body, design: .rounded, weight: .medium))
                .lineSpacing(3)
                .foregroundStyle(.primary)
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
