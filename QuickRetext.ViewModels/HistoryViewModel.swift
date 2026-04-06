import Combine
import Foundation
import QuickRetext_Models
import QuickRetext_Repositories

@MainActor
public final class HistoryViewModel: ObservableObject {

    @Published public var items: [HistoryItem] = []

    private let historyRepository: any HistoryRepositoryProtocol

    public init(history: any HistoryRepositoryProtocol) {
        self.historyRepository = history
    }

    public func loadItems() {
        do {
            items = try historyRepository.fetchAll()
        } catch {
            items = []
        }
    }

    public func restore(_ item: HistoryItem, to viewModel: MainViewModel) {
        viewModel.inputText  = item.inputText
        viewModel.outputText = ""
        viewModel.mode       = Mode(rawValue: item.mode) ?? .summarize
        viewModel.lengthStep = item.lengthStep
        viewModel.toneStep   = item.toneStep
        viewModel.lastExecutedLengthStep = nil
        viewModel.lastExecutedToneStep   = nil
    }

    public func delete(at indexSet: IndexSet) {
        for index in indexSet {
            let item = items[index]
            try? historyRepository.delete(item)
        }
        loadItems()
    }
}
