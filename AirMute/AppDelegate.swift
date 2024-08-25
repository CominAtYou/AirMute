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

        setUpRPCEvents(rpc)
        
        NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didLaunchApplicationNotification, object: nil, queue: nil) { notif in
            if let app = notif.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
                if app.bundleIdentifier == "com.hnc.Discord" {
                    self.statusItem.title = "Trying to connect..."
                    Task {
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
            self.statusItem.title = "Trying to connect..."
            Task {
                do {
                    try rpc.connect()
                }
                catch {
                    DispatchQueue.main.async {
                        self.statusItem.title = "Inactive — Can't Connect to Dicord"
                    }
                    logger.log("Couldn't establish connection: \(String(describing: error))")
                }
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
    
    
    @IBAction func menuItemClicked(_ sender: NSMenuItem) {
        if (sender.tag == 1) {
            NSWorkspace.shared.open(URL(string: "https://www.youtube.com/watch?v=FtutLA63Cp8")!)
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

