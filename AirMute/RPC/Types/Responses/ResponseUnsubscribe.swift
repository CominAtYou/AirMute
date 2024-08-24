import Foundation

public class ResponseUnsubscribe: Frame {
    let data: ResponseUnsubscribeData

    private enum CodingKeys: String, CodingKey {
        case data
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.data = try container.decode(ResponseUnsubscribeData.self, forKey: .data)
        try super.init(from: decoder, withFixedCmdType: .unsubscribe, withFixedEventType: nil, withNonce: true)
    }

    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(data, forKey: .data)
        try super.encode(to: encoder)
    }

    public override class func from(data: Data) throws -> ResponseUnsubscribe {
        return try NewJSONDecoder().decode(ResponseUnsubscribe.self, from: data)
    }
}

class ResponseUnsubscribeData: Codable {
    public let evt: EventType
}
