import Foundation
import QuickRetext_Models

public enum LanguageDetector {
    public static func detect(_ text: String) -> LanguageInstruction {
        let sample = String(text.prefix(100))
        let japaneseCount = sample.unicodeScalars.filter {
            ($0.value >= 0x3040 && $0.value <= 0x309F) ||  // ひらがな
            ($0.value >= 0x30A0 && $0.value <= 0x30FF) ||  // カタカナ
            ($0.value >= 0x4E00 && $0.value <= 0x9FFF)     // 漢字
        }.count
        return Double(japaneseCount) / Double(max(sample.count, 1)) >= 0.5
            ? .japanese : .english
    }
}
