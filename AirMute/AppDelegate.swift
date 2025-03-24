import AppKit
import AVFAudio
import Combine
import SwiftUI
import AVFoundation

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var controller: AudioInputController?
    var cancellable: AnyCancellable?
    var clientInitiatedAction = false
    var isMicrophoneConnected = false
    
    /// This exists as a secondary buffer for status text that isn't the "no microphone connected" text, as that must be displayed over all other text.
    var statusItemTitle = "Inactive — Discord Not Open"
    
    var statusBarMenuItem: NSStatusItem!
    var statusItem: NSMenuItem!
    
    var rpc: RPC?
    
    let windowDelegate = PreferencesWindowDelegate()
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        makeMenu()
        
        let clientId = UserDefaults.standard.string(forKey: "client_id")
        let clientSecret = UserDefaults.standard.string(forKey: "client_secret")
        
        if UserDefaults.standard.value(forKey: "click_to_deafen") == nil {
            UserDefaults.standard.set(true, forKey: "click_to_deafen")
        }
        
        Task {
            while true {
                if !isMicrophoneConnected && self.statusItem.title != "Inactive — No Microphone Connected" {
                    self.statusItem.title = "Inactive — No Microphone Connected"
                }
                else if isMicrophoneConnected && self.statusItem.title != statusItemTitle {
                    self.statusItem.title = self.statusItemTitle
                }
                
                try? await Task.sleep(nanoseconds: 250_000_000)
            }
        }
        
        if clientId == nil || clientId!.isEmpty || clientSecret == nil || clientSecret!.isEmpty {
            statusItemTitle = "Inactive — Missing Settings Values"
            return
        }
        
        if AVCaptureDevice.default(for: .audio) != nil {
            isMicrophoneConnected = true
            controller = AudioInputController()
        }
        
        let rpc = RPC(clientId: clientId!, clientSecret: clientSecret!)
        self.rpc = rpc

        setUpRPCEvents(rpc)
        
        NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didLaunchApplicationNotification, object: nil, queue: nil) { notif in
            if let app = notif.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
                if app.bundleIdentifier == "com.hnc.Discord" {
                    self.statusItemTitle = "Trying to connect..."
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
                    self.statusItemTitle = "Inactive — Discord Not Open"
                    self.controller?.stop()
                    self.rpc?.closeSocket()
                }
            }
        }
        
        if !NSRunningApplication.runningApplications(withBundleIdentifier: "com.hnc.Discord").isEmpty {
            self.statusItemTitle = "Trying to connect..."
            Task {
                do {
                    try rpc.connect()
                }
                catch {
                    DispatchQueue.main.async {
                        self.statusItemTitle = "Inactive — Can't Connect to Dicord"
                    }
                    logger.log("Couldn't establish connection: \(String(describing: error))")
                }
            }
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(audioCaptureDeviceConnected), name: AVCaptureDevice.wasConnectedNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(audioCaptureDeviceWasDisconnected), name: AVCaptureDevice.wasDisconnectedNotification, object: nil)
    }
    
    @objc func audioCaptureDeviceConnected(notification: Notification) {
        guard let device = notification.object as? AVCaptureDevice, device.hasMediaType(.audio) else {
            return
        }
        
        if (isMicrophoneConnected) { return }
        
        NSLog("An audio capture device was connected.")
        isMicrophoneConnected = true
        controller = AudioInputController()
    }
    
    @objc func audioCaptureDeviceWasDisconnected(notification: Notification) {
        guard let device = notification.object as? AVCaptureDevice, device.hasMediaType(.audio) else {
            return
        }
        
        if AVCaptureDevice.default(for: .audio) == nil {
            NSLog("An audio capture device was disconnected, and none are left.")
            isMicrophoneConnected = false
            controller = nil
        }
    }
    
    @objc func launchPreferences() {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        if let viewController = storyboard.instantiateController(withIdentifier: "PreferencesHostingController") as? NSHostingController<SettingsView> {
            guard !windowDelegate.isOpen else {
                NSApp.activate()
                NSApp.keyWindow?.orderFrontRegardless()
                return
            }
            
            let window = NSWindow(contentViewController: viewController)
            
            window.styleMask = [.titled, .closable]
            window.title = "AirMute — Settings"
            window.setContentSize(.init(width: 550, height: 375))
            window.center()
            
            window.delegate = windowDelegate
            
            let windowController = NSWindowController(window: window)
            windowController.showWindow(self)
            windowDelegate.isOpen = true
            windowController.window!.makeKey()
            NSApp.activate()
            NSApp.keyWindow?.orderFrontRegardless()
            return
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
        statusItem = NSMenuItem(title: statusItemTitle, action: nil, keyEquivalent: "")
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

