import SwiftUI

struct InputAreaView: View {
    @Binding var text: String
    let onClear: () -> Void

    private let maxLength = 1500

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            ZStack(alignment: .topTrailing) {
                TextEditor(text: $text)
                    .frame(minHeight: 160)

                if !text.isEmpty {
                    Button(action: onClear) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .padding(8)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
            )

            Text("\(text.count) / \(maxLength)")
                .font(.caption)
                .foregroundStyle(text.count > maxLength ? .red : .secondary)
        }
    }
}
