import Foundation
import SwiftData
import QuickRetext_Models

@MainActor
public final class HistoryRepository: HistoryRepositoryProtocol {
    private let container: ModelContainer

    public init(container: ModelContainer) {
        self.container = container
    }

    public func save(_ item: HistoryItem) throws {
        container.mainContext.insert(item)
        try container.mainContext.save()
    }

    public func fetchAll() throws -> [HistoryItem] {
        let descriptor = FetchDescriptor<HistoryItem>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try container.mainContext.fetch(descriptor)
    }

    public func delete(_ item: HistoryItem) throws {
        container.mainContext.delete(item)
        try container.mainContext.save()
    }
}
