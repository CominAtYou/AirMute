import Foundation

public class EventClose: Codable {
    public let code: CloseEventCode
    public let message: String

    init(code: CloseEventCode, message: String) {
        self.code = code
        self.message = message
    }

    public class func from(data: Data) throws -> EventClose {
        return try NewJSONDecoder().decode(EventClose.self, from: data)
    }
}
