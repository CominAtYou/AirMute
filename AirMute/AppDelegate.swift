import Cocoa
import AVFAudio
import Combine

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var controller = AudioInputController()!
    var cancellable: AnyCancellable?
    var clientInitiatedAction = false
    
    var statusBarMenuItem: NSStatusItem!
    var statusItem: NSMenuItem!
    
    var rpc: RPC?
    
    let windowDelegate = PreferencesWindowDelegate()
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        makeMenu()
        
        let clientId = UserDefaults.standard.string(forKey: "client_id")
        let clientSecret = UserDefaults.standard.string(forKey: "client_secret")
        
        if clientId == nil || clientId!.isEmpty || clientSecret == nil || clientSecret!.isEmpty {
            statusItem.title = "Inactive — Missing Settings Values"
        }
        
        let rpc = RPC(clientId: clientId!, clientSecret: clientSecret!)
        self.rpc = rpc
        
        rpc.onConnect { rpcParam, event in
            do {
                let authentication = try rpcParam.authenticateOverRPC()
                
                NSLog("Connected to @\(authentication.data.user.username)!")
                
                self.statusItem.title = "Inactive — Not in Voice"
                
                _ = try rpcParam.subscribe(event: .voiceConnectionStatus)
                _ = try rpcParam.subscribe(event: .voiceSettingsUpdate)
                
                try self.initMuteStateHandler(rpcParam)
                
                self.cancellable = NotificationCenter.default.publisher(for: AVAudioApplication.inputMuteStateChangeNotification)
                    .sink { notification in
                        // pass
                    }
            }
            catch {
                NSLog(String(describing: error))
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
                        self.statusItem.title = "Inactive — Not in Voice"
                        self.controller.stop()
                    }
                    else {
                        self.statusItem.title = "Active — In Voice"
                        self.controller.start()
                    }
                }
            }
        }
        
        NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didLaunchApplicationNotification, object: nil, queue: nil) { notif in
            if let app = notif.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
                if app.bundleIdentifier == "com.hnc.Discord" {
                    Task {
                        self.statusItem.title = "Trying to connect..."
                        while (true) {
                            do {
                                try rpc.connect()
                                break
                            }
                            catch {
                                try? await Task.sleep(nanoseconds: 5_000_000_000)
                            }
                        }
                    }
                }
            }
        }
        
        NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didTerminateApplicationNotification, object: nil, queue: nil) { notif in
            if let app = notif.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
                if app.bundleIdentifier == "com.hnc.Discord" {
                    self.statusItem.title = "Inactive — Discord Not Open"
                    self.controller.stop()
                    self.rpc?.closeSocket()
                }
            }
        }
        
        if !NSRunningApplication.runningApplications(withBundleIdentifier: "com.hnc.Discord").isEmpty {
            do {
                try rpc.connect()
            }
            catch {
                statusItem.title = "Inactive — Can't Connect to Dicord"
            }
        }
    }
    
    @objc func launchPreferences() {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        if let viewController = storyboard.instantiateController(withIdentifier: "PreferencesViewController") as? ViewController {
            if (windowDelegate.isOpen) {
                NSApp.keyWindow?.orderFront(self)
                NSApp.activate()
                return
            }
            
            let window = NSWindow(contentViewController: viewController)
            
            window.styleMask = [.titled, .closable, .miniaturizable]
            window.title = "AirMute — Settings"
            
            
            window.delegate = windowDelegate
            
            let controller = NSWindowController(window: window)
            controller.showWindow(self)
            windowDelegate.isOpen = true
            controller.window?.makeKeyAndOrderFront(self)
            NSApp.activate()
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        rpc?.closeSocket()
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
                .preferringHierarchical().applying(.init(textStyle: .body, scale: .medium).applying(.init(pointSize: 14, weight: .semibold)))
            )!
                
        image.size = NSSize(width: 24.0, height: 24.0)
        statusBarMenuItem.button!.image = image
        statusBarMenuItem.isVisible = true
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}

