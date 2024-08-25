import Foundation

public class ResponseGetVoiceSettings: Codable {
    let data: ResponseGetVoiceSettingsData
    
    private enum CodingKeys: String, CodingKey {
        case data
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.data = try container.decode(ResponseGetVoiceSettingsData.self, forKey: .data)
    }
    
    static func from(data: Data) throws -> ResponseGetVoiceSettings {
        return try JSONDecoder().decode(Self.self, from: data)
    }
}

public class ResponseGetVoiceSettingsData: Codable {
    let mute: Bool
    let deaf: Bool
}
