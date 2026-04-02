import SwiftUI

struct OutputAreaView: View {
    let text: String
    let lastExecutedLabel: String?

    @State private var isCopied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // 実行済み粒度ラベル
            if let label = lastExecutedLabel, !text.isEmpty {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ZStack(alignment: .topTrailing) {
                if text.isEmpty {
                    TextEditor(text: .constant(""))
                        .frame(minHeight: 160)
                        .disabled(true)
                        .overlay(
                            Text("変換結果がここに表示されます")
                                .foregroundStyle(.tertiary)
                                .padding(8),
                            alignment: .topLeading
                        )
                } else {
                    ScrollView {
                        Text(text)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(8)
                    }
                    .frame(minHeight: 160)

                    Button(action: copyText) {
                        Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                            .foregroundStyle(isCopied ? .green : .secondary)
                    }
                    .padding(8)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
            )

            if !text.isEmpty {
                Text("\(text.count) 文字")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func copyText() {
        UIPasteboard.general.string = text
        isCopied = true
        Task {
            try? await Task.sleep(for: .seconds(1))
            isCopied = false
        }
    }
}
