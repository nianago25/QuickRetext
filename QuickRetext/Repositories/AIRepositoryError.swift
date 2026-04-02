import Foundation

enum AIRepositoryError: Error, Equatable {
    case modelUnavailable
    case inputTooLong
    case generationFailed
    case unknown(Error)

    static func == (lhs: AIRepositoryError, rhs: AIRepositoryError) -> Bool {
        switch (lhs, rhs) {
        case (.modelUnavailable, .modelUnavailable): return true
        case (.inputTooLong, .inputTooLong):         return true
        case (.generationFailed, .generationFailed): return true
        case (.unknown, .unknown):                   return true
        default:                                      return false
        }
    }
}
