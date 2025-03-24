import AVFAudio

extension AppDelegate {
    func initMuteStateHandler(_ rpc: RPC) throws {
        try AVAudioApplication.shared.setInputMuteStateChangeHandler { isMuted in
            if self.clientInitiatedAction {
                self.clientInitiatedAction = false
                return true
            }
            
            guard let voiceSettings = try? rpc.getVoiceSettings() else { return false }
            
            if voiceSettings.data.deaf {
                if isMuted { return true }
                
                if UserDefaults.standard.bool(forKey: "click_to_undeafen") {
                    do {
                        try rpc.setMicMuted(isMuted)
                        return true
                    }
                    catch { return false }
                }
                else { return false }
            }
            
            do {
                try rpc.setMicMuted(isMuted)
                return true
            }
            catch { return false }
        }
    }
}
