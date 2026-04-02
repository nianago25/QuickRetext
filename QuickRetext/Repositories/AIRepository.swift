import Foundation

#if canImport(FoundationModels)
import FoundationModels

@available(iOS 26.0, *)
final class AIRepository: AIRepositoryProtocol, @unchecked Sendable {
    private let model: SystemLanguageModel

    init() throws {
        let systemModel = SystemLanguageModel.default
        // availability は .available / .unavailable(reason:) の enum
        guard case .available = systemModel.availability else {
            throw AIRepositoryError.modelUnavailable
        }
        self.model = systemModel
    }

    func summarize(
        input: String,
        length: LengthInstruction,
        language: LanguageInstruction
    ) async throws -> String {
        let systemPrompt = """
        あなたはテキスト要約の専門家です。
        ユーザーが入力したテキストを、指示に従って要約します。
        - 出力は要約結果のみとし、前置き・説明・コメントは一切含めない
        - 元の意味・ニュアンスを正確に保つ
        - 内容に応じて箇条書きと文章を使い分けてよい
        """

        let userPrompt = """
        以下のテキストを要約してください。

        \(language.instruction)
        \(length.instruction)

        テキスト:
        \(input)
        """

        return try await generate(systemPrompt: systemPrompt, userPrompt: userPrompt, temperature: 0.2)
    }

    func rewrite(
        input: String,
        tone: ToneInstruction,
        language: LanguageInstruction
    ) async throws -> String {
        let systemPrompt = """
        あなたはテキストリライトの専門家です。
        ユーザーが入力したテキストを、指定されたトーンで書き直します。
        - 出力はリライト結果のみとし、前置き・説明・コメントは一切含めない
        - 意味は保持しつつ、読みやすさを最優先する
        - 内容に応じて箇条書きと文章を使い分けてよい
        """

        let userPrompt = """
        以下のテキストを書き直してください。

        \(language.instruction)
        \(tone.instruction)

        テキスト:
        \(input)
        """

        return try await generate(systemPrompt: systemPrompt, userPrompt: userPrompt, temperature: 0.4)
    }

    // MARK: - Private

    private func generate(systemPrompt: String, userPrompt: String, temperature: Double) async throws -> String {
        do {
            let session = LanguageModelSession(model: model, instructions: systemPrompt)
            let options = GenerationOptions(
                temperature: temperature,
                maximumResponseTokens: 800
            )
            let response = try await session.respond(to: userPrompt, options: options)
            return response.content
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw AIRepositoryError.generationFailed
        }
    }
}

#else

// FoundationModels が利用できない SDK でのフォールバック（開発・CI 用）
@available(iOS 26.0, *)
final class AIRepository: AIRepositoryProtocol, @unchecked Sendable {
    init() throws { throw AIRepositoryError.modelUnavailable }

    func summarize(input: String, length: LengthInstruction, language: LanguageInstruction) async throws -> String {
        throw AIRepositoryError.modelUnavailable
    }
    func rewrite(input: String, tone: ToneInstruction, language: LanguageInstruction) async throws -> String {
        throw AIRepositoryError.modelUnavailable
    }
}

#endif

// MARK: - Unavailable Stub

final class AIRepositoryUnavailable: AIRepositoryProtocol, Sendable {
    func summarize(input: String, length: LengthInstruction, language: LanguageInstruction) async throws -> String {
        throw AIRepositoryError.modelUnavailable
    }

    func rewrite(input: String, tone: ToneInstruction, language: LanguageInstruction) async throws -> String {
        throw AIRepositoryError.modelUnavailable
    }
}
