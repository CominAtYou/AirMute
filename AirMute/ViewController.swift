import Cocoa

class ViewController: NSViewController, NSTextFieldDelegate {
    @IBOutlet weak var clientIdTextField: NumericTextField!
    @IBOutlet weak var clientSecretTextField: NSTextField!
    @IBOutlet weak var textFieldDescription: NSTextField!
    @IBOutlet weak var undeafenOnClickCheckbox: NSButton!
    @IBOutlet weak var undeafenOnClickDescriptionLabel: NSTextField!
    @IBOutlet weak var versionLabel: NSTextField!
    @IBOutlet weak var launchOnStartupCheckbox: NSButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        clientIdTextField.delegate = self
        clientSecretTextField.delegate = self
        undeafenOnClickCheckbox.target = self

        clientIdTextField.stringValue = UserDefaults.standard.string(forKey: "client_id") ?? ""
        clientSecretTextField.stringValue = UserDefaults.standard.string(forKey: "client_secret") ?? ""
        undeafenOnClickCheckbox.state = !UserDefaults.standard.bool(forKey: "disable_click_to_undeafen") ? .on : .off
        undeafenOnClickDescriptionLabel.stringValue = !UserDefaults.standard.bool(forKey: "disable_click_to_undeafen") ? "When deafened, clicking the stem or pressing the digital crown will undeafen and unmute you." : "When deafened, clicking the stem or pressing the digital crown will not do anything."
        
        launchOnStartupCheckbox.state = UserDefaults.standard.bool(forKey: "launch_on_startup") ? .on : .off
        
        undeafenOnClickCheckbox.action = #selector(undeafenOnClickCheckboxStateChanged)
        launchOnStartupCheckbox.action = #selector(launchOnStartupCheckboxStateChanged)
        
        versionLabel.stringValue = "AirMute \(Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String) (\(Bundle.main.infoDictionary!["CFBundleVersion"] as! String))"
    }
    
    func controlTextDidEndEditing(_ obj: Notification) {
        guard let textField = obj.object as? NSTextField else { return }
        
        if textField == clientIdTextField {
            UserDefaults.standard.setValue(textField.stringValue, forKey: "client_id")
        }
        
        if textField == clientSecretTextField {
            UserDefaults.standard.setValue(textField.stringValue, forKey: "client_secret")
        }
    }
    
    @objc func undeafenOnClickCheckboxStateChanged(_ sender: NSButton) {
        let isClickToDeafenDisabled = sender.state == .off
        
        UserDefaults.standard.set(isClickToDeafenDisabled, forKey: "disable_click_to_undeafen")
        undeafenOnClickDescriptionLabel.stringValue = isClickToDeafenDisabled ? "When deafened, clicking the stem or pressing the digital crown will not do anything." : "When deafened, clicking the stem or pressing the digital crown will undeafen and unmute you."
    }
    
    @objc func launchOnStartupCheckboxStateChanged(_ sender: NSButton) {
        UserDefaults.standard.setValue(sender.state == .on, forKey: "launch_on_startup")
        
        if sender.state == .on {
            let plist: NSDictionary = [
                "Label": "AirMute",
                "AssociatedBundleIdentifiers": Bundle.main.bundleIdentifier!,
                "ProgramArguments": ["open", "/Applications/AirMute.app"],
                "RunAtLoad": true,
                "AbandonProcessGroup": true
            ]
            
            let filePath = FileManager.default.homeDirectoryForCurrentUser.appending(path: "/Library/LaunchAgents/AirMute.plist")
            if FileManager.default.createFile(atPath: filePath.path(), contents: nil) {
                try? plist.write(to: filePath)
            }
        }
        else {
            let filePath = FileManager.default.homeDirectoryForCurrentUser.appending(path: "/Library/LaunchAgents/AirMute.plist")
            try? FileManager.default.removeItem(at: filePath)
        }
    }
    
    @IBAction func onHelpButtonClicked(_ sender: NSButton) {
        NSWorkspace.shared.open(URL(string: "https://github.com/CominAtYou/AirMute/tree/master?tab=readme-ov-file#something-not-working")!)
    }
    
    override func viewWillDisappear() {
        UserDefaults.standard.setValue(clientIdTextField.stringValue, forKey: "client_id")
        UserDefaults.standard.setValue(clientSecretTextField.stringValue, forKey: "client_secret")
    }
}

