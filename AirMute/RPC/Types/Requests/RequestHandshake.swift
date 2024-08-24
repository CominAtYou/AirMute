import Foundation

class RequestHandshake: Encodable {
    let v: Int = apiVersion
    let clientID: String

    private enum CodingKeys: String, CodingKey {
        case v
        case clientID = "client_id"
    }

    init(clientID: String) throws {
        self.clientID = clientID
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(v, forKey: .v)
        try container.encode(clientID, forKey: .clientID)
    }

    func jsonData() throws -> Data {
        return try NewJSONEncoder().encode(self)
    }

    func jsonString() throws -> String {
        return String(data: try self.jsonData(), encoding: .utf8)!
    }
}
