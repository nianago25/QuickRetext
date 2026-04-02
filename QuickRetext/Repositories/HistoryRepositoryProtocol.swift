import Foundation

@MainActor
protocol HistoryRepositoryProtocol {
    func save(_ item: HistoryItem) throws
    func fetchAll() throws -> [HistoryItem]
    func delete(_ item: HistoryItem) throws
}
