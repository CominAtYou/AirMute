import Foundation

enum ControlError: Error {
    case stateMismatch
}

extension RPC {
    func setMicMuted(_ isMuted: Bool) throws {
        let nonce = "sync;\(UUID().uuidString)"
        
        let settings = ["nonce": nonce, "args": ["mute": isMuted], "cmd": "SET_VOICE_SETTINGS"] as [String : Any]
        let settingsJSON = try JSONSerialization.data(withJSONObject: settings, options: [])
        
        let response = try syncResponse(requestJSON: String(data: settingsJSON, encoding: .utf8)!, nonce: nonce, disableTimeout: false)
        let responseSvc = try ResponseGetVoiceSettings.from(data: response)
        
        if isMuted != responseSvc.data.mute {
            throw ControlError.stateMismatch
        }
    }
    
    func getVoiceSettings() throws -> ResponseGetVoiceSettings {
        let nonce = "sync;\(UUID().uuidString)"
        
        let payload = ["nonce": nonce, "args": [], "cmd": "GET_VOICE_SETTINGS"] as [String : Any]
        let payloadJSON = try JSONSerialization.data(withJSONObject: payload, options: [])
        
        let response = try syncResponse(requestJSON: String(data: payloadJSON, encoding: .utf8)!, nonce: nonce, disableTimeout: false)
        return try ResponseGetVoiceSettings.from(data: response)
    }
}
