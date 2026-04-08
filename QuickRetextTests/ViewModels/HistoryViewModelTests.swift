import Testing
import Foundation
@testable import QuickRetext_Models
@testable import QuickRetext_Repositories
@testable import QuickRetext_ViewModels

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

    // MARK: - deleteAll

    @Test("deleteAll で全件削除される")
    func deleteAllRemovesAllItems() {
        let historyRepo = MockHistoryRepository()
        historyRepo.savedItems = [
            HistoryItem(inputText: "a", outputText: "b", mode: .summarize, lengthStep: 0, toneStep: 0),
            HistoryItem(inputText: "c", outputText: "d", mode: .rewrite, lengthStep: 1, toneStep: 1),
        ]

        let vm = HistoryViewModel(history: historyRepo)
        vm.loadItems()
        #expect(vm.items.count == 2)

        vm.deleteAll()

        #expect(vm.items.isEmpty)
        #expect(historyRepo.savedItems.isEmpty)
    }

    @Test("deleteAll でリポジトリが失敗しても items が空になる")
    func deleteAllHandlesError() {
        let historyRepo = MockHistoryRepository()
        historyRepo.savedItems = [
            HistoryItem(inputText: "a", outputText: "b", mode: .summarize, lengthStep: 0, toneStep: 0),
        ]
        historyRepo.shouldThrowOnDeleteAll = true

        let vm = HistoryViewModel(history: historyRepo)
        vm.loadItems()
        vm.deleteAll()

        // エラー時でもリロードされる（fetchAll で残存アイテムが返る）
        #expect(vm.items.count == 1)
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
        #expect(mainVM.outputText == "restored output")
        #expect(mainVM.mode == .rewrite)
        #expect(mainVM.lengthStep == 2)
        #expect(mainVM.toneStep == 3)
        #expect(mainVM.lastExecutedLengthStep == nil)
        #expect(mainVM.lastExecutedToneStep == nil)
    }
}
