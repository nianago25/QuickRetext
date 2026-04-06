import Foundation

public enum LengthInstruction: Equatable {
    case ultraShort
    case concise
    case balanced
    case detailed

    public var instruction: String {
        switch self {
        case .ultraShort: return "できるだけ短く、1〜2文で答えてください。"
        case .concise:    return "要点のみを簡潔にまとめてください。"
        case .balanced:   return "重要な情報を残しながら適切な長さにまとめてください。"
        case .detailed:   return "情報をできるだけ保持しながら、読みやすくまとめてください。"
        }
    }

    public static func from(_ step: Int) -> LengthInstruction {
        switch step {
        case 0:  return .ultraShort
        case 1:  return .concise
        case 2:  return .balanced
        case 3:  return .detailed
        default: return .ultraShort
        }
    }

    public static func label(for step: Int) -> String {
        switch step {
        case 0:  return "短く"
        case 1:  return "簡潔"
        case 2:  return "標準"
        case 3:  return "詳しく"
        default: return "短く"
        }
    }
}
