import Testing
import SwiftData
import Foundation
@testable import QuickRetext_Models
@testable import QuickRetext_Repositories

@Suite("HistoryRepository Tests")
@MainActor
struct HistoryRepositoryTests {

    private func makeRepository() throws -> HistoryRepository {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: HistoryItem.self, configurations: config)
        return HistoryRepository(container: container)
    }

    // MARK: - save & fetchAll

    @Test("save したアイテムが fetchAll で取得できる")
    func saveAndFetch() throws {
        let repo = try makeRepository()
        let item = HistoryItem(inputText: "input", outputText: "output", mode: .summarize, lengthStep: 1, toneStep: 2)

        try repo.save(item)
        let fetched = try repo.fetchAll()

        #expect(fetched.count == 1)
        #expect(fetched[0].inputText == "input")
        #expect(fetched[0].outputText == "output")
        #expect(fetched[0].mode == Mode.summarize.rawValue)
        #expect(fetched[0].lengthStep == 1)
        #expect(fetched[0].toneStep == 2)
    }

    @Test("fetchAll は createdAt の降順で返す")
    func fetchAllSortedDescending() throws {
        let repo = try makeRepository()

        let older = HistoryItem(inputText: "older", outputText: "a", mode: .summarize, lengthStep: 0, toneStep: 0)
        older.createdAt = Date(timeIntervalSince1970: 1000)

        let newer = HistoryItem(inputText: "newer", outputText: "b", mode: .rewrite, lengthStep: 1, toneStep: 1)
        newer.createdAt = Date(timeIntervalSince1970: 2000)

        try repo.save(older)
        try repo.save(newer)
        let fetched = try repo.fetchAll()

        #expect(fetched.count == 2)
        #expect(fetched[0].inputText == "newer")
        #expect(fetched[1].inputText == "older")
    }

    // MARK: - delete

    @Test("delete で指定アイテムのみ削除される")
    func deleteSingleItem() throws {
        let repo = try makeRepository()
        let item1 = HistoryItem(inputText: "keep", outputText: "a", mode: .summarize, lengthStep: 0, toneStep: 0)
        let item2 = HistoryItem(inputText: "remove", outputText: "b", mode: .rewrite, lengthStep: 1, toneStep: 1)

        try repo.save(item1)
        try repo.save(item2)
        try repo.delete(item2)

        let fetched = try repo.fetchAll()
        #expect(fetched.count == 1)
        #expect(fetched[0].inputText == "keep")
    }

    // MARK: - deleteAll

    @Test("deleteAll で全件削除される")
    func deleteAllItems() throws {
        let repo = try makeRepository()
        try repo.save(HistoryItem(inputText: "a", outputText: "1", mode: .summarize, lengthStep: 0, toneStep: 0))
        try repo.save(HistoryItem(inputText: "b", outputText: "2", mode: .rewrite, lengthStep: 1, toneStep: 1))
        try repo.save(HistoryItem(inputText: "c", outputText: "3", mode: .summarize, lengthStep: 2, toneStep: 2))

        #expect(try repo.fetchAll().count == 3)

        try repo.deleteAll()

        #expect(try repo.fetchAll().isEmpty)
    }

    @Test("空の状態で deleteAll を呼んでもエラーにならない")
    func deleteAllWhenEmpty() throws {
        let repo = try makeRepository()
        try repo.deleteAll()
        #expect(try repo.fetchAll().isEmpty)
    }
}
