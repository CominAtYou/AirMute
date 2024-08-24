import Foundation

public enum RequestError: Error {
    case invalidParameters(reason: String)
}
extension RequestError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidParameters(let reason):
            return NSLocalizedString(
                "Invalid parameters: \(reason)",
                comment: ""
            )
        }
    }
}
