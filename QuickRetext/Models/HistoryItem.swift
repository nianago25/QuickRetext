import SwiftData
import Foundation

@Model
final class HistoryItem: Identifiable {
    var id: UUID
    var inputText: String
    var outputText: String
    var mode: String      // Mode.rawValue を保存
    var lengthStep: Int   // 0〜3
    var toneStep: Int     // 0〜3
    var createdAt: Date

    init(
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
