import SwiftUI

struct SpinningVinyl: View {
    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .fill(.black)
                .frame(width: 220, height: 220)
                .shadow(color: .black.opacity(0.5), radius: 20)

            Circle()
                .stroke(Color(.systemGray5), lineWidth: 1)
                .frame(width: 200, height: 200)

            ForEach(0..<8) { i in
                Circle()
                    .stroke(Color(.systemGray6).opacity(0.3), lineWidth: 0.5)
                    .frame(width: CGFloat(200 - i * 25), height: CGFloat(200 - i * 25))
            }

            Circle()
                .fill(Color(hex: "#E8A850"))
                .frame(width: 50, height: 50)

            Circle()
                .fill(.black)
                .frame(width: 8, height: 8)
        }
        .rotationEffect(.degrees(rotation))
        .onAppear {
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}
