import Foundation
import QuickRetext_Models
import QuickRetext_Repositories

// MARK: - MockAIRepository

final class MockAIRepository: AIRepositoryProtocol, Sendable {
    // 呼び出し記録
    nonisolated(unsafe) var summarizeCalled = false
    nonisolated(unsafe) var rewriteCalled = false
    nonisolated(unsafe) var lastSummarizeLength: LengthInstruction?
    nonisolated(unsafe) var lastRewriteTone: ToneInstruction?

    // 注入する結果
    nonisolated(unsafe) var resultToReturn: Result<String, AIRepositoryError> = .success("mock output")
    nonisolated(unsafe) var shouldCancel = false
    nonisolated(unsafe) var delay: Duration = .milliseconds(0)

    func summarize(
        input: String,
        length: LengthInstruction,
        language: LanguageInstruction
    ) async throws -> String {
        summarizeCalled = true
        lastSummarizeLength = length
        if delay > .milliseconds(0) {
            try await Task.sleep(for: delay)
        }
        if shouldCancel { throw CancellationError() }
        switch resultToReturn {
        case .success(let text): return text
        case .failure(let error): throw error
        }
    }

    func rewrite(
        input: String,
        tone: ToneInstruction,
        language: LanguageInstruction
    ) async throws -> String {
        rewriteCalled = true
        lastRewriteTone = tone
        if delay > .milliseconds(0) {
            try await Task.sleep(for: delay)
        }
        if shouldCancel { throw CancellationError() }
        switch resultToReturn {
        case .success(let text): return text
        case .failure(let error): throw error
        }
    }
}

// MARK: - MockHistoryRepository

@MainActor
final class MockHistoryRepository: HistoryRepositoryProtocol {
    var savedItems: [HistoryItem] = []
    var shouldThrowOnSave = false
    var shouldThrowOnFetch = false
    var shouldThrowOnDelete = false
    var shouldThrowOnDeleteAll = false

    func save(_ item: HistoryItem) throws {
        if shouldThrowOnSave { throw NSError(domain: "test", code: 1) }
        savedItems.append(item)
    }

    func fetchAll() throws -> [HistoryItem] {
        if shouldThrowOnFetch { throw NSError(domain: "test", code: 2) }
        return savedItems
    }

    func delete(_ item: HistoryItem) throws {
        if shouldThrowOnDelete { throw NSError(domain: "test", code: 3) }
        savedItems.removeAll { $0.id == item.id }
    }

    func deleteAll() throws {
        if shouldThrowOnDeleteAll { throw NSError(domain: "test", code: 4) }
        savedItems.removeAll()
    }
}
