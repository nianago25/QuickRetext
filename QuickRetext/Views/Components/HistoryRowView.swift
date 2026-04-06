import SwiftUI
import QuickRetext_Models

struct HistoryRowView: View {
    let item: HistoryItem

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy/MM/dd HH:mm"
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(Mode(rawValue: item.mode)?.displayLabel ?? item.mode)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.tint.opacity(0.15))
                    .clipShape(Capsule())

                Spacer()

                Text(Self.dateFormatter.string(from: item.createdAt))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(item.inputText)
                .lineLimit(1)
                .font(.subheadline)
        }
        .padding(.vertical, 4)
    }
}
