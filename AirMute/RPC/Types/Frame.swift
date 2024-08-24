import Foundation

public class Frame: Codable {
    public let cmd: CommandType
    public let evt: EventType?
    public let nonce: String?

    private enum CodingKeys: String, CodingKey {
        case cmd
        case evt
        case nonce
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.cmd = try container.decode(CommandType.self, forKey: .cmd)
        self.evt = try? container.decode(EventType.self, forKey: .evt)
        self.nonce = try? container.decode(String.self, forKey: .nonce)
    }

    private func validateCmd(withFixedCmdType: CommandType) throws {
        if self.cmd != withFixedCmdType {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: [CodingKeys.cmd],
                    debugDescription: """
                        Cannot initialize key because actual value(\(self.cmd)) \
                        mismatch with required value(\(withFixedCmdType))
                    """
                )
            )
        }
    }

    private func validateEvt(withFixedEventType: EventType?) throws {
        if self.evt != withFixedEventType {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: [CodingKeys.evt],
                    debugDescription: """
                        Cannot initialize key because actual value(\(self.evt?.rawValue ?? "nil")) \
                        mismatch with required value(\(withFixedEventType?.rawValue ?? "nil"))
                    """
                )
            )
        }
    }

    private func validateNonce(withNonce: Bool) throws {
        if withNonce && (self.nonce == nil || self.nonce!.trimmingCharacters(in: .whitespacesAndNewlines).count == 0) {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: [CodingKeys.nonce],
                    debugDescription: "Cannot initialize key because required value is nil or empty"
                )
            )
        }
        if !withNonce && self.nonce != nil {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: [CodingKeys.nonce],
                    debugDescription: "Cannot initialize key because value is required to be nil but it's not"
                )
            )
        }
    }

    init (from decoder: Decoder, withNonce: Bool) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.cmd = try container.decode(CommandType.self, forKey: .cmd)
        self.evt = try? container.decode(EventType.self, forKey: .evt)
        self.nonce = try? container.decode(String.self, forKey: .nonce)
        try validateNonce(withNonce: withNonce)
    }

    init(from decoder: Decoder, withFixedCmdType: CommandType, withNonce: Bool) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.cmd = try container.decode(CommandType.self, forKey: .cmd)
        self.evt = try? container.decode(EventType.self, forKey: .evt)
        self.nonce = try? container.decode(String.self, forKey: .nonce)
        try validateCmd(withFixedCmdType: withFixedCmdType)
        try validateNonce(withNonce: withNonce)
    }

    init(from decoder: Decoder, withFixedEventType: EventType?, withNonce: Bool) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.cmd = try container.decode(CommandType.self, forKey: .cmd)
        self.evt = try? container.decode(EventType.self, forKey: .evt)
        self.nonce = try? container.decode(String.self, forKey: .nonce)
        try validateEvt(withFixedEventType: withFixedEventType)
        try validateNonce(withNonce: withNonce)
    }

    init(from decoder: Decoder, withFixedCmdType: CommandType, withFixedEventType: EventType?, withNonce: Bool) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.cmd = try container.decode(CommandType.self, forKey: .cmd)
        self.evt = try? container.decode(EventType.self, forKey: .evt)
        self.nonce = try? container.decode(String.self, forKey: .nonce)
        try validateCmd(withFixedCmdType: withFixedCmdType)
        try validateEvt(withFixedEventType: withFixedEventType)
        try validateNonce(withNonce: withNonce)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(cmd, forKey: .cmd)
        if evt != nil { try container.encode(evt, forKey: .evt) }
        if nonce != nil { try container.encode(nonce, forKey: .nonce) }
    }

    public class func from(data: Data) throws -> Frame {
        return try NewJSONDecoder().decode(Frame.self, from: data)
    }
}
