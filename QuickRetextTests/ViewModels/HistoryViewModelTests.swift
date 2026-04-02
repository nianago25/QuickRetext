import Testing
import Foundation
@testable import QuickRetext

@Suite("HistoryViewModel Tests")
@MainActor
struct HistoryViewModelTests {

    // MARK: - loadItems

    @Test("loadItems で items が取得される")
    func loadItemsFetchesItems() throws {
        let historyRepo = MockHistoryRepository()
        let item = HistoryItem(inputText: "input", outputText: "output", mode: .summarize, lengthStep: 0, toneStep: 2)
        historyRepo.savedItems = [item]

        let vm = HistoryViewModel(history: historyRepo)
        vm.loadItems()

        #expect(vm.items.count == 1)
        #expect(vm.items[0].inputText == "input")
    }

    @Test("fetchAll が失敗したとき items は空になる")
    func loadItemsReturnsEmptyOnError() {
        let historyRepo = MockHistoryRepository()
        historyRepo.shouldThrowOnFetch = true

        let vm = HistoryViewModel(history: historyRepo)
        vm.loadItems()

        #expect(vm.items.isEmpty)
    }

    // MARK: - delete

    @Test("delete で items から対象が削除される")
    func deleteRemovesItem() throws {
        let historyRepo = MockHistoryRepository()
        let item = HistoryItem(inputText: "a", outputText: "b", mode: .rewrite, lengthStep: 1, toneStep: 1)
        historyRepo.savedItems = [item]

        let vm = HistoryViewModel(history: historyRepo)
        vm.loadItems()
        vm.delete(at: IndexSet(integer: 0))

        #expect(vm.items.isEmpty)
        #expect(historyRepo.savedItems.isEmpty)
    }

    // MARK: - restore

    @Test("restore で mainViewModel の各プロパティが復元される")
    func restoreUpdatesMainViewModel() {
        let historyRepo = MockHistoryRepository()
        let vm = HistoryViewModel(history: historyRepo)

        let mainVM = MainViewModel(ai: MockAIRepository(), history: historyRepo, isModelAvailable: true)
        mainVM.inputText  = "old input"
        mainVM.outputText = "old output"
        mainVM.lastExecutedLengthStep = 3
        mainVM.lastExecutedToneStep   = 3

        let item = HistoryItem(inputText: "restored input", outputText: "restored output", mode: .rewrite, lengthStep: 2, toneStep: 3)
        vm.restore(item, to: mainVM)

        #expect(mainVM.inputText == "restored input")
        #expect(mainVM.outputText.isEmpty)
        #expect(mainVM.mode == .rewrite)
        #expect(mainVM.lengthStep == 2)
        #expect(mainVM.toneStep == 3)
        #expect(mainVM.lastExecutedLengthStep == nil)
        #expect(mainVM.lastExecutedToneStep == nil)
    }
}
