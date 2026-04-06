import Combine
import UIKit
import QuickRetext_Models
import QuickRetext_Repositories
import QuickRetext_Utilities

@MainActor
public final class MainViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published public var inputText: String = ""
    @Published public var outputText: String = ""
    @Published public var mode: Mode = .summarize
    @Published public var lengthStep: Int = 0   // 0〜3、デフォルト：ultraShort（短く）
    @Published public var toneStep: Int = 2     // 0〜3、デフォルト：formal（丁寧）
    @Published public var lastExecutedLengthStep: Int? = nil
    @Published public var lastExecutedToneStep: Int? = nil
    @Published public var isProcessing: Bool = false
    @Published public var errorMessage: String?
    @Published public var showErrorAlert: Bool = false
    @Published public var isModelAvailable: Bool = true
    @Published public var showModelUnavailableAlert: Bool = false
    @Published public var showModeChangedCancelAlert: Bool = false

    // MARK: - Private Properties

    private let aiRepository: any AIRepositoryProtocol
    private let historyRepository: any HistoryRepositoryProtocol
    private var currentTask: Task<Void, Never>?
    // セッション中に1回だけモード変更キャンセルダイアログを表示する制御フラグ
    private var hasShownModeChangeCancelAlert: Bool = false

    // MARK: - Computed Properties

    public var canConvert: Bool {
        isModelAvailable && !inputText.isEmpty && inputText.count <= 1500
    }

    // MARK: - Init

    public init(ai: any AIRepositoryProtocol, history: any HistoryRepositoryProtocol, isModelAvailable: Bool) {
        self.aiRepository = ai
        self.historyRepository = history
        self.isModelAvailable = isModelAvailable
        if !isModelAvailable {
            self.showModelUnavailableAlert = true
        }
    }

    // MARK: - Convert

    public func convert(lengthStep step: Int) {
        guard canConvert, !isProcessing else { return }
        lengthStep = step
        currentTask?.cancel()
        currentTask = Task {
            await runConvert {
                let language = LanguageDetector.detect(self.inputText)
                let length = LengthInstruction.from(step)
                return try await self.aiRepository.summarize(
                    input: self.inputText,
                    length: length,
                    language: language
                )
            } onSuccess: {
                self.lastExecutedLengthStep = step
                self.lastExecutedToneStep = nil
            }
        }
    }

    public func convert(toneStep step: Int) {
        guard canConvert, !isProcessing else { return }
        toneStep = step
        currentTask?.cancel()
        currentTask = Task {
            await runConvert {
                let language = LanguageDetector.detect(self.inputText)
                let tone = ToneInstruction.from(step)
                return try await self.aiRepository.rewrite(
                    input: self.inputText,
                    tone: tone,
                    language: language
                )
            } onSuccess: {
                self.lastExecutedToneStep = step
                self.lastExecutedLengthStep = nil
            }
        }
    }

    // MARK: - Cancel

    public func cancel() {
        currentTask?.cancel()
        currentTask = nil
        isProcessing = false
    }

    // MARK: - Mode Change

    public func handleModeChange() {
        guard isProcessing else { return }
        currentTask?.cancel()
        isProcessing = false
        if !hasShownModeChangeCancelAlert {
            showModeChangedCancelAlert = true
            hasShownModeChangeCancelAlert = true
        }
    }

    // MARK: - Input

    public func clearInput() {
        inputText = ""
        outputText = ""
        lastExecutedLengthStep = nil
        lastExecutedToneStep = nil
    }

    public func loadClipboardIfNeeded(isEnabled: Bool) {
        guard isEnabled,
              inputText.isEmpty,
              UIPasteboard.general.hasStrings,
              let text = UIPasteboard.general.string,
              !text.isEmpty else { return }
        inputText = text
    }

    // MARK: - Private

    private func runConvert(
        _ work: @escaping () async throws -> String,
        onSuccess: @escaping () -> Void
    ) async {
        isProcessing = true
        errorMessage = nil
        defer { isProcessing = false }

        do {
            let result = try await work()
            guard !Task.isCancelled else { return }
            outputText = result
            onSuccess()
            let item = HistoryItem(
                inputText: inputText,
                outputText: result,
                mode: mode,
                lengthStep: lengthStep,
                toneStep: toneStep
            )
            try? historyRepository.save(item)
        } catch is CancellationError {
            // キャンセルはユーザーに通知しない
        } catch let error as AIRepositoryError {
            handleAIError(error)
        } catch {
            errorMessage = "予期しないエラーが発生しました。もう一度お試しください。"
            showErrorAlert = true
        }
    }

    private func handleAIError(_ error: AIRepositoryError) {
        switch error {
        case .generationFailed:
            errorMessage = "テキストの変換中にエラーが発生しました。もう一度お試しください。"
        case .inputTooLong:
            errorMessage = "入力テキストを1500文字以内にしてください。"
        case .unknown:
            errorMessage = "予期しないエラーが発生しました。もう一度お試しください。"
        case .modelUnavailable:
            break // 起動時に処理済み
        }
        showErrorAlert = (errorMessage != nil)
    }
}
