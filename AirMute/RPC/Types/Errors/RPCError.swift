import Foundation

public enum RPCError: Error {
    case appSandboxed
    case socketCreation(error: Error?)
    case udsNotFound(path: String)
}
extension RPCError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .appSandboxed:
            return NSLocalizedString(
                "Can't connect using UDS RPC within a sandboxed app",
                comment: ""
            )
        case .socketCreation(let error):
            return NSLocalizedString(
                "Socket creation failed\(error != nil ? ": \(error!.localizedDescription)" : "")",
                comment: ""
            )
        case .udsNotFound(let path):
            return NSLocalizedString(
                "Discord Unix Domain Socket not found in path: \(path)",
                comment: ""
            )
        }
    }
}
