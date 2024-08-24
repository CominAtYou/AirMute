import Foundation

public class ResponseAuthorize: Frame {
    public let data: ResponseAuthorizeData

    private enum CodingKeys: String, CodingKey {
        case data
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.data = try container.decode(ResponseAuthorizeData.self, forKey: .data)
        try super.init(from: decoder, withFixedCmdType: .authorize, withFixedEventType: nil, withNonce: true)
    }

    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(data, forKey: .data)
        try super.encode(to: encoder)
    }

    public override class func from(data: Data) throws -> ResponseAuthorize {
        return try NewJSONDecoder().decode(ResponseAuthorize.self, from: data)
    }
}

public class ResponseAuthorizeData: Codable {
    public let code: String
}
