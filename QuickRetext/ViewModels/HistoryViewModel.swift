import Combine
import Foundation

@MainActor
final class HistoryViewModel: ObservableObject {

    @Published var items: [HistoryItem] = []

    private let historyRepository: any HistoryRepositoryProtocol

    init(history: any HistoryRepositoryProtocol) {
        self.historyRepository = history
    }

    func loadItems() {
        do {
            items = try historyRepository.fetchAll()
        } catch {
            items = []
        }
    }

    func restore(_ item: HistoryItem, to viewModel: MainViewModel) {
        viewModel.inputText  = item.inputText
        viewModel.outputText = ""
        viewModel.mode       = Mode(rawValue: item.mode) ?? .summarize
        viewModel.lengthStep = item.lengthStep
        viewModel.toneStep   = item.toneStep
        viewModel.lastExecutedLengthStep = nil
        viewModel.lastExecutedToneStep   = nil
    }

    func delete(at indexSet: IndexSet) {
        for index in indexSet {
            let item = items[index]
            try? historyRepository.delete(item)
        }
        loadItems()
    }
}
