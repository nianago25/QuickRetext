import SwiftData
import Foundation
import QuickRetext_Models
import QuickRetext_Repositories

/// アプリ全体のリポジトリを生成・保持する DI コンテナ（値型）。
/// ViewModel は各 View が @StateObject で所有する。
@MainActor
struct AppDependencies {
    let aiRepository: any AIRepositoryProtocol
    let historyRepository: any HistoryRepositoryProtocol
    let isModelAvailable: Bool

    init() {
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

        let container: ModelContainer
        do {
            container = try ModelContainer(for: HistoryItem.self)
        } catch {
            fatalError("SwiftData ModelContainer の初期化に失敗しました: \(error)")
        }

        aiRepository      = ai
        historyRepository = HistoryRepository(container: container)
        isModelAvailable  = modelAvailable
    }
}
