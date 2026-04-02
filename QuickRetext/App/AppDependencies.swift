import SwiftData
import Combine
import Foundation

/// アプリ全体のリポジトリを生成・保持する DI コンテナ。
/// ViewModel は各 View が @StateObject で所有する。
@MainActor
final class AppDependencies: ObservableObject {
    nonisolated let objectWillChange = ObservableObjectPublisher()

    let aiRepository: any AIRepositoryProtocol
    let historyRepository: any HistoryRepositoryProtocol
    let isModelAvailable: Bool

    init() {
        // AIRepository 生成失敗時はアプリ起動を継続し、
        // MainViewModel 側で isModelAvailable=false にしてダイアログ表示する
        let aiResult: Result<any AIRepositoryProtocol, Error>
        if #available(iOS 26.0, *) {
            aiResult = Result { try AIRepository() }
        } else {
            aiResult = .failure(AIRepositoryError.modelUnavailable)
        }

        let ai: any AIRepositoryProtocol
        let modelAvailable: Bool
        switch aiResult {
        case .success(let repo):
            ai = repo
            modelAvailable = true
        case .failure:
            ai = AIRepositoryUnavailable()
            modelAvailable = false
        }

        // ModelContainer 生成失敗は致命的エラーのため try! を許可
        let container = try! ModelContainer(for: HistoryItem.self)

        aiRepository      = ai
        historyRepository = HistoryRepository(container: container)
        isModelAvailable  = modelAvailable
    }
}
