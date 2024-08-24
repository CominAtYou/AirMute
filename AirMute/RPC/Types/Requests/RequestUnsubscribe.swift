import Foundation

class RequestUnsubscribe: Encodable {
    var cmd: CommandType = .unsubscribe
    let evt: EventType
    let nonce: String
    let args: RequestUnsubscribeArgs?

    private enum CodingKeys: String, CodingKey {
        case cmd
        case evt
        case nonce
        case args
    }

    init(evt: EventType, nonce: String, id: String?) throws {
        self.evt = evt
        self.nonce = nonce

        switch evt {
        case .ready, .error:
            throw RequestError.invalidParameters(reason: "impossible to unsubscribe to \(evt) event")
        case .guildStatus:
            if id == nil {
                throw RequestError.invalidParameters(reason: "you must provide a guild ID for guild_status event")
            }
            self.args = try RequestUnsubscribeArgs(guildID: id, channelID: nil)
        case .voiceStateCreate,
             .voiceStateUpdate,
             .voiceStateDelete,
             .messageCreate,
             .messageUpdate,
             .messageDelete,
             .speakingStart,
             .speakingStop:
            if id == nil {
                throw RequestError.invalidParameters(reason: "you must provide a channel ID for \(evt) event")
            }
            self.args = try RequestUnsubscribeArgs(guildID: nil, channelID: id)
        default:
            if id != nil {
                throw RequestError.invalidParameters(reason: "you must not provide any ID for \(evt) event")
            }
            self.args = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(cmd, forKey: .cmd)
        try container.encode(evt, forKey: .evt)
        try container.encode(nonce, forKey: .nonce)
        if self.args != nil { try container.encode(args, forKey: .args) }
    }

    func jsonData() throws -> Data {
        return try NewJSONEncoder().encode(self)
    }

    func jsonString() throws -> String {
        return String(data: try self.jsonData(), encoding: .utf8)!
    }
}

class RequestUnsubscribeArgs: Encodable {
    let guildID: String?
    let channelID: String?

    private enum CodingKeys: String, CodingKey {
        case guildID = "guild_id"
        case channelID = "channel_id"
    }

    init(guildID: String?, channelID: String?) throws {
        if (guildID == nil && channelID == nil) || (guildID != nil && channelID != nil) {
            throw RequestError.invalidParameters(reason: "one channelID xor guildID must be provided")
        }

        self.channelID = channelID
        self.guildID = guildID
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if self.guildID != nil { try container.encode(guildID, forKey: .guildID) }
        if self.channelID != nil { try container.encode(channelID, forKey: .channelID) }
    }
}
