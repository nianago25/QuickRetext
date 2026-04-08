import SwiftUI
import QuickRetext_Models
import QuickRetext_Repositories
import QuickRetext_ViewModels

struct HistoryView: View {
    @StateObject private var viewModel: HistoryViewModel
    @EnvironmentObject private var settingViewModel: SettingViewModel
    /// restore 呼び出し先。所有はしない
    private let mainViewModel: MainViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isShowingDeleteAllConfirmation = false

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
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(role: .destructive) {
                    isShowingDeleteAllConfirmation = true
                } label: {
                    Image(systemName: "trash")
                }
                .disabled(viewModel.items.isEmpty)
            }
        }
        .confirmationDialog("全件削除", isPresented: $isShowingDeleteAllConfirmation) {
            Button("すべて削除", role: .destructive) {
                viewModel.deleteAll()
            }
        } message: {
            Text("すべての履歴を削除しますか？この操作は取り消せません。")
        }
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
