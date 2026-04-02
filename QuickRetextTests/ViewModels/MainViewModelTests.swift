import Testing
@testable import QuickRetext

@Suite("MainViewModel Tests")
@MainActor
struct MainViewModelTests {

    // MARK: - canConvert

    @Test("入力が空のとき canConvert は false")
    func canConvertFalseWhenInputEmpty() {
        let vm = MainViewModel(ai: MockAIRepository(), history: MockHistoryRepository(), isModelAvailable: true)
        vm.inputText = ""
        #expect(vm.canConvert == false)
    }

    @Test("入力が1500文字以内のとき canConvert は true")
    func canConvertTrueWhenInputValid() {
        let vm = MainViewModel(ai: MockAIRepository(), history: MockHistoryRepository(), isModelAvailable: true)
        vm.inputText = String(repeating: "あ", count: 100)
        #expect(vm.canConvert == true)
    }

    @Test("入力が1500文字を超えるとき canConvert は false")
    func canConvertFalseWhenInputTooLong() {
        let vm = MainViewModel(ai: MockAIRepository(), history: MockHistoryRepository(), isModelAvailable: true)
        vm.inputText = String(repeating: "a", count: 1501)
        #expect(vm.canConvert == false)
    }

    @Test("モデルが利用不可のとき canConvert は false")
    func canConvertFalseWhenModelUnavailable() {
        let vm = MainViewModel(ai: MockAIRepository(), history: MockHistoryRepository(), isModelAvailable: false)
        vm.inputText = "テスト"
        #expect(vm.canConvert == false)
    }

    @Test("入力がちょうど1500文字のとき canConvert は true")
    func canConvertTrueWhenInputExactly1500() {
        let vm = MainViewModel(ai: MockAIRepository(), history: MockHistoryRepository(), isModelAvailable: true)
        vm.inputText = String(repeating: "a", count: 1500)
        #expect(vm.canConvert == true)
    }

    // MARK: - convert(lengthStep:)

    @Test("convert(lengthStep:) 成功時に outputText が更新される")
    func convertLengthStepUpdatesOutputText() async {
        let mock = MockAIRepository()
        mock.resultToReturn = .success("要約結果")
        let vm = MainViewModel(ai: mock, history: MockHistoryRepository(), isModelAvailable: true)
        vm.inputText = "テスト入力"

        vm.convert(lengthStep: 2)
        // Task の完了を待つ
        try? await Task.sleep(for: .milliseconds(100))

        #expect(vm.outputText == "要約結果")
        #expect(mock.summarizeCalled == true)
        #expect(mock.lastSummarizeLength == .balanced)
    }

    @Test("convert(lengthStep:) 成功後に lastExecutedLengthStep が更新される")
    func convertLengthStepUpdatesLastExecuted() async {
        let mock = MockAIRepository()
        mock.resultToReturn = .success("result")
        let vm = MainViewModel(ai: mock, history: MockHistoryRepository(), isModelAvailable: true)
        vm.inputText = "テスト"

        vm.convert(lengthStep: 1)
        try? await Task.sleep(for: .milliseconds(100))

        #expect(vm.lastExecutedLengthStep == 1)
    }

    @Test("convert(lengthStep:) 成功後に履歴が保存される")
    func convertSavesHistory() async {
        let mock = MockAIRepository()
        mock.resultToReturn = .success("output")
        let historyRepo = MockHistoryRepository()
        let vm = MainViewModel(ai: mock, history: historyRepo, isModelAvailable: true)
        vm.inputText = "input text"

        vm.convert(lengthStep: 0)
        try? await Task.sleep(for: .milliseconds(100))

        #expect(historyRepo.savedItems.count == 1)
        #expect(historyRepo.savedItems[0].inputText == "input text")
        #expect(historyRepo.savedItems[0].outputText == "output")
    }

    @Test("convert(lengthStep:) 失敗時に errorMessage がセットされる")
    func convertFailureSetsErrorMessage() async {
        let mock = MockAIRepository()
        mock.resultToReturn = .failure(.generationFailed)
        let vm = MainViewModel(ai: mock, history: MockHistoryRepository(), isModelAvailable: true)
        vm.inputText = "テスト"

        vm.convert(lengthStep: 0)
        try? await Task.sleep(for: .milliseconds(100))

        #expect(vm.errorMessage != nil)
        #expect(vm.showErrorAlert == true)
        #expect(vm.outputText.isEmpty)
    }

    // MARK: - convert(toneStep:)

    @Test("convert(toneStep:) 成功時に rewrite が呼ばれる")
    func convertToneStepCallsRewrite() async {
        let mock = MockAIRepository()
        mock.resultToReturn = .success("リライト結果")
        let vm = MainViewModel(ai: mock, history: MockHistoryRepository(), isModelAvailable: true)
        vm.inputText = "テスト入力"
        vm.mode = .rewrite

        vm.convert(toneStep: 3)
        try? await Task.sleep(for: .milliseconds(100))

        #expect(mock.rewriteCalled == true)
        #expect(mock.lastRewriteTone == .business)
        #expect(vm.outputText == "リライト結果")
    }

    // MARK: - cancel

    @Test("cancel() 呼び出し後に isProcessing が false になる")
    func cancelStopsProcessing() async {
        let mock = MockAIRepository()
        mock.delay = .seconds(10)
        let vm = MainViewModel(ai: mock, history: MockHistoryRepository(), isModelAvailable: true)
        vm.inputText = "テスト"

        vm.convert(lengthStep: 0)
        try? await Task.sleep(for: .milliseconds(50))
        #expect(vm.isProcessing == true)

        vm.cancel()
        try? await Task.sleep(for: .milliseconds(50))
        #expect(vm.isProcessing == false)
    }

    @Test("キャンセル時に lastExecutedLengthStep は更新されない")
    func cancelDoesNotUpdateLastExecuted() async {
        let mock = MockAIRepository()
        mock.delay = .seconds(10)
        let vm = MainViewModel(ai: mock, history: MockHistoryRepository(), isModelAvailable: true)
        vm.inputText = "テスト"
        #expect(vm.lastExecutedLengthStep == nil)

        vm.convert(lengthStep: 2)
        try? await Task.sleep(for: .milliseconds(50))
        vm.cancel()
        try? await Task.sleep(for: .milliseconds(50))

        #expect(vm.lastExecutedLengthStep == nil)
    }

    // MARK: - clearInput

    @Test("全削除ボタンで inputText・outputText・lastExecuted がリセットされる")
    func clearInputResetsState() {
        let vm = MainViewModel(ai: MockAIRepository(), history: MockHistoryRepository(), isModelAvailable: true)
        vm.inputText = "some text"
        vm.outputText = "some output"
        vm.lastExecutedLengthStep = 2
        vm.lastExecutedToneStep = 1

        vm.clearInput()

        #expect(vm.inputText.isEmpty)
        #expect(vm.outputText.isEmpty)
        #expect(vm.lastExecutedLengthStep == nil)
        #expect(vm.lastExecutedToneStep == nil)
    }

    // MARK: - handleModeChange

    @Test("isProcessing=false のときモード変更してもアラートは出ない")
    func handleModeChangeNoAlertWhenNotProcessing() {
        let vm = MainViewModel(ai: MockAIRepository(), history: MockHistoryRepository(), isModelAvailable: true)
        vm.handleModeChange()
        #expect(vm.showModeChangedCancelAlert == false)
    }

    @Test("isProcessing=true のときモード変更でアラートが表示される")
    func handleModeChangeDuringProcessingShowsAlert() async {
        let mock = MockAIRepository()
        mock.delay = .seconds(10)
        let vm = MainViewModel(ai: mock, history: MockHistoryRepository(), isModelAvailable: true)
        vm.inputText = "テスト"

        vm.convert(lengthStep: 0)
        try? await Task.sleep(for: .milliseconds(50))

        vm.handleModeChange()

        #expect(vm.showModeChangedCancelAlert == true)
        #expect(vm.isProcessing == false)
    }

    // MARK: - モデル未対応

    @Test("モデル未対応時に初期化でアラートフラグが立つ")
    func modelUnavailableShowsAlert() {
        let vm = MainViewModel(ai: MockAIRepository(), history: MockHistoryRepository(), isModelAvailable: false)
        #expect(vm.showModelUnavailableAlert == true)
        #expect(vm.isModelAvailable == false)
    }
}
