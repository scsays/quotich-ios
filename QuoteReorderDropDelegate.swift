import SwiftUI
import UniformTypeIdentifiers

struct QuoteReorderDropDelegate: DropDelegate {
    let targetID: UUID
    @Binding var items: [Quote]
    @Binding var draggingID: UUID?

    var onDropEnded: (() -> Void)? = nil

    func validateDrop(info: DropInfo) -> Bool {
        info.hasItemsConforming(to: [UTType.plainText, UTType.text])
    }

    func dropEntered(info: DropInfo) {
        guard let draggingID, draggingID != targetID else { return }

        guard
            let fromIndex = items.firstIndex(where: { $0.id == draggingID }),
            let toIndex   = items.firstIndex(where: { $0.id == targetID })
        else { return }

        guard fromIndex != toIndex else { return }

        withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
            items.move(
                fromOffsets: IndexSet(integer: fromIndex),
                toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex
            )
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        draggingID = nil
        onDropEnded?()
        return true
    }
}
