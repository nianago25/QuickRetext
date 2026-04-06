import SwiftData
import Foundation

@Model
public final class HistoryItem: Identifiable {
    public var id: UUID
    public var inputText: String
    public var outputText: String
    public var mode: String      // Mode.rawValue を保存
    public var lengthStep: Int   // 0〜3
    public var toneStep: Int     // 0〜3
    public var createdAt: Date

    public init(
        inputText: String,
        outputText: String,
        mode: Mode,
        lengthStep: Int,
        toneStep: Int
    ) {
        self.id         = UUID()
        self.inputText  = inputText
        self.outputText = outputText
        self.mode       = mode.rawValue
        self.lengthStep = lengthStep
        self.toneStep   = toneStep
        self.createdAt  = Date()
    }
}
