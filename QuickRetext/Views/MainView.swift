import SwiftUI

struct MainView: View {
    @StateObject private var viewModel: MainViewModel
    @EnvironmentObject private var settingViewModel: SettingViewModel
    @Environment(\.scenePhase) private var scenePhase
    /// HistoryView 生成時に渡すため保持（MainView 自身は直接使用しない）
    private let historyRepository: any HistoryRepositoryProtocol

    init(
        aiRepository: any AIRepositoryProtocol,
        historyRepository: any HistoryRepositoryProtocol,
        isModelAvailable: Bool
    ) {
        _viewModel = StateObject(wrappedValue: MainViewModel(
            ai: aiRepository,
            history: historyRepository,
            isModelAvailable: isModelAvailable
        ))
        self.historyRepository = historyRepository
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    InputAreaView(
                        text: $viewModel.inputText,
                        onClear: { viewModel.clearInput() }
                    )

                    OutputAreaView(
                        text: viewModel.outputText,
                        lastExecutedLabel: lastExecutedLabel
                    )
                }
                .padding()
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 0) {
                    ControlPanelView(viewModel: viewModel)
                    AdBannerView(isVisible: !settingViewModel.isAdRemoved)
                }
            }
            .navigationTitle("クイックリテキスト")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink {
                        SettingView()
                    } label: {
                        Image(systemName: "gearshape.fill")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        HistoryView(
                            historyRepository: historyRepository,
                            mainViewModel: viewModel
                        )
                    } label: {
                        Image(systemName: "clock.fill")
                    }
                }
            }
            .alert("エラーが発生しました", isPresented: $viewModel.showErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .alert("この端末では利用できません", isPresented: $viewModel.showModelUnavailableAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("本アプリはApple Intelligence対応端末でのみご利用いただけます。")
            }
            .alert("処理を停止しました", isPresented: $viewModel.showModeChangedCancelAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("モード変更のため、現在の処理を停止しました。")
            }
            .onChange(of: viewModel.mode) { _, _ in
                viewModel.handleModeChange()
            }
            .onChange(of: scenePhase) { _, newPhase in
                guard newPhase == .active else { return }
                viewModel.loadClipboardIfNeeded(
                    isEnabled: settingViewModel.isClipboardAutoLoadEnabled
                )
            }
        }
    }

    private var lastExecutedLabel: String? {
        switch viewModel.mode {
        case .summarize:
            guard let step = viewModel.lastExecutedLengthStep else { return nil }
            return LengthInstruction.label(for: step)
        case .rewrite:
            guard let step = viewModel.lastExecutedToneStep else { return nil }
            return ToneInstruction.label(for: step)
        }
    }
}
