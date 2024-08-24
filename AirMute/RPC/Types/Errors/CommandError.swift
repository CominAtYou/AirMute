import Foundation

public enum CommandError: Error {
    case timeout(timeout: Int)
    case responseMalformed(response: Notification?)
    case failed(code: ErrorCode, message: String)
}
extension CommandError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .timeout(let timeout):
            return NSLocalizedString(
                "Response took to much time and command has timeout (\(timeout)ms)",
                comment: ""
            )
        case .responseMalformed(let response):
            return NSLocalizedString(
                "Command returned a malformed response: \(String(describing: response!.userInfo))",
                comment: ""
            )
        case .failed(let code, let message):
            return NSLocalizedString(
                "Command returned an error (\(code)): \(message)",
                comment: ""
            )
        }
    }
}
