import Foundation

public enum NonceError: Error {
    case invalid(nonce: String)
}
extension NonceError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalid(let nonce):
            return NSLocalizedString(
                "Invalid nonce (\(nonce)) not an UUID prefixed by either 'async;' or 'sync;'",
                comment: ""
            )
        }
    }
}
