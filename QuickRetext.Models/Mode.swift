import Foundation

public enum Mode: String, CaseIterable {
    case summarize = "summarize"
    case rewrite   = "rewrite"

    public var displayLabel: String {
        switch self {
        case .summarize: return "要約"
        case .rewrite:   return "リライト"
        }
    }
}
