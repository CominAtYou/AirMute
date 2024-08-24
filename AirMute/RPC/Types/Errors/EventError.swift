import Foundation

public class EventError: Frame {
    public let data: EventErrorData

    private enum CodingKeys: String, CodingKey {
        case data
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.data = try container.decode(EventErrorData.self, forKey: .data)
        try super.init(from: decoder, withFixedEventType: .error, withNonce: true)
    }

    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(data, forKey: .data)
        try super.encode(to: encoder)
    }

    public override class func from(data: Data) throws -> EventError {
        return try NewJSONDecoder().decode(EventError.self, from: data)
    }
}

public class EventErrorData: Codable {
    public let code: ErrorCode
    public let message: String
}
