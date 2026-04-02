import Foundation

enum LanguageInstruction {
    case japanese
    case english

    var instruction: String {
        switch self {
        case .japanese: return "必ず日本語で出力してください。"
        case .english:  return "Output in English only."
        }
    }
}
