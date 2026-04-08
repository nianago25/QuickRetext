import Foundation
import QuickRetext_Models

@MainActor
public protocol HistoryRepositoryProtocol {
    func save(_ item: HistoryItem) throws
    func fetchAll() throws -> [HistoryItem]
    func delete(_ item: HistoryItem) throws
    func deleteAll() throws
}
