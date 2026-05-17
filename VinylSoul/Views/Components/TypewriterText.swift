import SwiftUI

struct TypewriterText: View {
    let text: String

    var body: some View {
        Text(text.isEmpty ? " " : text)
            .font(.system(.body, design: .serif))
            .foregroundStyle(.primary)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
    }
}
