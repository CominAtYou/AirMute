import Foundation

public class RPCToken: Codable {
    public let rpcToken: String

    private enum CodingKeys: String, CodingKey {
        case rpcToken = "rpc_token"
    }

    class func from(data: Data) throws -> RPCToken {
        return try NewJSONDecoder().decode(RPCToken.self, from: data)
    }
}
