import Foundation

public class EventVoiceConnectionStatus: Codable {
    let data: EventVoiceConnectionStatusData
    
    private enum CodingKeys: String, CodingKey {
        case data
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.data = try container.decode(EventVoiceConnectionStatusData.self, forKey: .data)
    }
    
    static func from(data: Data) throws -> EventVoiceConnectionStatus {
        return try JSONDecoder().decode(Self.self, from: data)
    }
}

public class EventVoiceConnectionStatusData: Codable {
    let state: VoiceState
}
