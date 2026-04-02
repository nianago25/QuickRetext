import Foundation

protocol AIRepositoryProtocol: Sendable {
    func summarize(
        input: String,
        length: LengthInstruction,
        language: LanguageInstruction
    ) async throws -> String

    func rewrite(
        input: String,
        tone: ToneInstruction,
        language: LanguageInstruction
    ) async throws -> String
}
