import Foundation

public enum LanguageInstruction {
    case japanese
    case english

    public var instruction: String {
        switch self {
        case .japanese: return "必ず日本語で出力してください。"
        case .english:  return "Output in English only."
        }
    }
}
