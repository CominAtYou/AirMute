import Foundation
import AVFAudio

extension AppDelegate {
    func setUpRPCEvents(_ rpc: RPC) {
        rpc.onConnect { rpcParam, event in
            do {
                let authentication = try rpcParam.authenticateOverRPC()
                
                NSLog("Connected to @\(authentication.data.user.username)!")
                
                DispatchQueue.main.async {
                    self.statusItem.title = "Inactive — Not in Voice"
                }
                
                _ = try rpcParam.subscribe(event: .voiceConnectionStatus)
                _ = try rpcParam.subscribe(event: .voiceSettingsUpdate)
                
                try self.initMuteStateHandler(rpcParam)
                
                self.cancellable = NotificationCenter.default.publisher(for: AVAudioApplication.inputMuteStateChangeNotification)
                    .sink { notification in
                        // pass
                    }
            }
            catch HTTPError.failed(let code, let error) {
                DispatchQueue.main.async {
                    if (code == 401) {
                        self.statusItem.title = "Error — Invalid Client Secret"
                        rpc.closeSocket()
                    }
                    else {
                        self.statusItem.title = "Error — Unable to Connect"
                        logger.error("Got HTTP error \(code ?? -1): \(String(describing: error))")
                    }
                }
            }
            catch CommandError.failed(let code, let errorMessage) {
                DispatchQueue.main.async {
                    if code == .oAuth2Error {
                        self.statusItem.title = "Error — Couldn't Obtain Authorization"
                    }
                    else {
                        self.statusItem.title = "Error — Command Failed"
                        logger.error("Got command error \(String(describing: code)): \(errorMessage)")
                    }
                }
            }
            catch {
                logger.error("onConnect block error: \(String(describing: error))")
            }
        }
        
        rpc.onEvent { rpcParam, eventType, event in
            if eventType == .voiceSettingsUpdate {
                if let responseSvc = try? ResponseGetVoiceSettings.from(data: event) {
                    self.clientInitiatedAction = true
                    try? AVAudioApplication.shared.setInputMuted(responseSvc.data.deaf || responseSvc.data.mute)
                }
            }
            else if eventType == .voiceConnectionStatus {
                if let eventData = try? EventVoiceConnectionStatus.from(data: event) {
                    if eventData.data.state == .disconnected {
                        DispatchQueue.main.async {
                            self.statusItem.title = "Inactive — Not in Voice"
                        }
                        self.controller.stop()
                    }
                    else {
                        DispatchQueue.main.async {
                            self.statusItem.title = "Active — In Voice"
                        }
                        self.controller.start()
                    }
                }
            }
        }
        
        rpc.onDisconnect { rpcParam, event in
            DispatchQueue.main.async {
                switch event.code {
                case .invalidClientID:
                    self.statusItem.title = "Error — Invalid Client ID"
                case .invalidOrigin:
                    self.statusItem.title = "Error — Invalid RPC Origin"
                case .tokenRevoked:
                    self.statusItem.title = "Error — Invalid Token"
                case .socketDisconnected:
                    break
                default:
                    self.statusItem.title = "Error — Unable to Connect"
                    logger.error("Got disocnnect OpCode: \(String(describing: event.code)) \(event.message)")
                }
            }
        }
    }
}