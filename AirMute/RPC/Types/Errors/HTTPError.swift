import Foundation

public enum HTTPError: Error {
    case timeout(timeout: Int)
    case failed(code: Int?, error: Error?)
}
extension HTTPError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .timeout(let timeout):
            return NSLocalizedString(
                "Response took to much time and request has timeout (\(timeout)ms)",
                comment: ""
            )
        case .failed(let code, let error):
            return NSLocalizedString(
                "Request returned an error (\(code ?? 0))\(error != nil ? ": \(error!.localizedDescription)" : "")",
                comment: ""
            )
        }
    }
}
