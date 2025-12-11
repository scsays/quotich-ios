import SwiftUI

struct ScrollPhaseTracking: ViewModifier {
    @Binding var isScrolling: Bool

    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.onScrollPhaseChange { _, newPhase in
                // Anything other than .idle means movement is happening
                isScrolling = (newPhase != .idle)
            }
        } else {
            content
        }
    }
}

extension View {
    func trackScrollPhase(isScrolling: Binding<Bool>) -> some View {
        modifier(ScrollPhaseTracking(isScrolling: isScrolling))
    }
}
