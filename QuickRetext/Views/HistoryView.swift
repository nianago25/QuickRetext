import SwiftUI

struct HistoryView: View {
    @StateObject private var viewModel: HistoryViewModel
    @EnvironmentObject private var settingViewModel: SettingViewModel
    /// restore 呼び出し先。所有はしない
    private let mainViewModel: MainViewModel
    @Environment(\.dismiss) private var dismiss

    init(historyRepository: any HistoryRepositoryProtocol, mainViewModel: MainViewModel) {
        _viewModel = StateObject(wrappedValue: HistoryViewModel(history: historyRepository))
        self.mainViewModel = mainViewModel
    }

    var body: some View {
        List {
            ForEach(viewModel.items) { item in
                HistoryRowView(item: item)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.restore(item, to: mainViewModel)
                        dismiss()
                    }
            }
            .onDelete { indexSet in
                viewModel.delete(at: indexSet)
            }
        }
        .safeAreaInset(edge: .bottom) {
            AdBannerView(isVisible: !settingViewModel.isAdRemoved)
        }
        .navigationTitle("変換履歴")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadItems()
        }
        .overlay {
            if viewModel.items.isEmpty {
                ContentUnavailableView(
                    "履歴がありません",
                    systemImage: "clock",
                    description: Text("変換した結果がここに表示されます")
                )
            }
        }
    }
}
