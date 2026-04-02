import Foundation

enum ToneInstruction: Equatable {
    case casual
    case polite
    case formal
    case business

    var instruction: String {
        switch self {
        case .casual:   return "フレンドリーでカジュアルな口調で書いてください。"
        case .polite:   return "やや丁寧で読みやすい口調で書いてください。"
        case .formal:   return "丁寧で誠実な口調で書いてください。"
        case .business: return "ビジネス文書として適切なフォーマルな口調で書いてください。"
        }
    }

    static func from(_ step: Int) -> ToneInstruction {
        switch step {
        case 0:  return .casual
        case 1:  return .polite
        case 2:  return .formal
        case 3:  return .business
        default: return .casual
        }
    }

    static func label(for step: Int) -> String {
        switch step {
        case 0:  return "カジュアル"
        case 1:  return "普通"
        case 2:  return "丁寧"
        case 3:  return "ビジネス"
        default: return "カジュアル"
        }
    }
}
