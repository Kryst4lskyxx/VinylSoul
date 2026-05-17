import SwiftUI

struct StyleTagChip: View {
    let style: StyleTag
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            Text(style.rawValue)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(isSelected ? Color(hex: "#E8A850") : Color(.systemGray6))
                .foregroundStyle(isSelected ? .black : .primary)
                .clipShape(Capsule())
        }
    }
}
