import Cocoa
import AVFAudio
import Combine

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    private var controller: AudioInputController?
    private var cancellable: AnyCancellable?
    private var clientInitiatedAction = false
    
    private var statusBarMenuItem: NSStatusItem!
    private var statusItem: NSMenuItem!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        makeMenu()
        
        let clientId = UserDefaults.standard.string(forKey: "client_id")
        let clientSecret = UserDefaults.standard.string(forKey: "client_secret")
        
        if clientId == nil || clientId!.isEmpty || clientSecret == nil || clientSecret!.isEmpty {
            statusItem.title = "Inactive — Missing Settings Values"
        }
        
        let rpc = RPC(clientId: clientId!, clientSecret: clientSecret!)
        
        rpc.onConnect { rpcParam, event in
            do {
                let authentication = try rpc.authenticateOverRPC()
                
                NSLog("Connected to @\(authentication.data.user.username)!")
                
                self.statusItem.title = "Inactive — Not in Voice"
                
                _ = try rpc.subscribe(event: .voiceConnectionStatus)
                _ = try rpc.subscribe(event: .voiceSettingsUpdate)
                
                try! AVAudioApplication.shared.setInputMuteStateChangeHandler { isMuted in
                    if self.clientInitiatedAction {
                        self.clientInitiatedAction = false
                        return true
                    }
                    
                    guard let voiceSettings = try? rpcParam.getVoiceSettings() else { return false }
                    
                    if voiceSettings.data.deaf {
                        if isMuted { return true }
                        
                        if !UserDefaults.standard.bool(forKey: "disable_click_to_undeafen") {
                            do {
                                try rpcParam.setMicMuted(isMuted)
                                return true
                            }
                            catch { return false }
                        }
                        else { return false }
                    }
                    
                    do {
                        try rpcParam.setMicMuted(isMuted)
                        return true
                    }
                    catch { return false }
                }
                
                self.cancellable = NotificationCenter.default.publisher(for: AVAudioApplication.inputMuteStateChangeNotification)
                    .sink { notification in
                        // pass
                    }
                
                
                self.controller = AudioInputController()!
                self.controller!.start()
            }
            catch {
                NSLog(String(describing: error))
            }
        }

        rpc.onEvent { rpc, eventType, event in
            if eventType == .voiceSettingsUpdate {
                if let responseSvc = try? ResponseGetVoiceSettings.from(data: event) {
                    self.clientInitiatedAction = true
                    try? AVAudioApplication.shared.setInputMuted(responseSvc.data.deaf || responseSvc.data.mute)
                }
            }
        }
        
        try! rpc.connect()
    }
    
    @objc func launchPreferences() {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        if let viewController = storyboard.instantiateController(withIdentifier: "PreferencesViewController") as? ViewController {
            let window = NSWindow(contentViewController: viewController)
            
            window.makeKeyAndOrderFront(self)
            window.styleMask = [.titled, .closable, .miniaturizable]
            window.title = "AirMute — Settings"
            
            let controller = NSWindowController(window: window)
            controller.showWindow(self)
            NSApp.activate()
            controller.window?.makeKeyAndOrderFront(self)
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func makeMenu() {
        let menu = NSMenu()
        statusItem = NSMenuItem(title: "Inactive — Discord Not Open", action: nil, keyEquivalent: "")
        statusItem.isEnabled = false
        menu.addItem(statusItem)
        
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(launchPreferences), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate), keyEquivalent: ""))
        
        statusBarMenuItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusBarMenuItem.menu = menu
        
        let image = NSImage(systemSymbolName: "person.wave.2.fill", accessibilityDescription: nil)!
            .withSymbolConfiguration(
                NSImage.SymbolConfiguration(textStyle: .body, scale: .medium).applying(.init(pointSize: 14, weight: .semibold))
            )!
                
        image.size = NSSize(width: 24.0, height: 24.0)
        statusBarMenuItem.button!.image = image
        statusBarMenuItem.isVisible = true
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}

