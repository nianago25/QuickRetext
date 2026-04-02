import Foundation
import SwiftData

@MainActor
final class HistoryRepository: HistoryRepositoryProtocol {
    private let container: ModelContainer

    init(container: ModelContainer) {
        self.container = container
    }

    func save(_ item: HistoryItem) throws {
        container.mainContext.insert(item)
        try container.mainContext.save()
    }

    func fetchAll() throws -> [HistoryItem] {
        let descriptor = FetchDescriptor<HistoryItem>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try container.mainContext.fetch(descriptor)
    }

    func delete(_ item: HistoryItem) throws {
        container.mainContext.delete(item)
        try container.mainContext.save()
    }
}
