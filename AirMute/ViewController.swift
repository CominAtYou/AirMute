import Cocoa

class ViewController: NSViewController, NSTextFieldDelegate {
    @IBOutlet weak var clientIdTextField: NumericTextField!
    @IBOutlet weak var clientSecretTextField: NSTextField!
    @IBOutlet weak var textFieldDescription: NSTextField!
    @IBOutlet weak var undeafenOnClickCheckbox: NSButton!
    @IBOutlet weak var undeafenOnClickDescriptionLabel: NSTextField!
    @IBOutlet weak var versionLabel: NSTextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        clientIdTextField.delegate = self
        clientSecretTextField.delegate = self
        undeafenOnClickCheckbox.target = self

        clientIdTextField.stringValue = UserDefaults.standard.string(forKey: "client_id") ?? ""
        clientSecretTextField.stringValue = UserDefaults.standard.string(forKey: "client_secret") ?? ""
        undeafenOnClickCheckbox.state = !UserDefaults.standard.bool(forKey: "disable_click_to_undeafen") ? .on : .off
        undeafenOnClickDescriptionLabel.stringValue = !UserDefaults.standard.bool(forKey: "disable_click_to_undeafen") ? "When deafened, clicking the stem or pressing the digital crown will undeafen and unmute you." : "When deafened, clicking the stem or pressing the digital crown will not do anything."
        
        undeafenOnClickCheckbox.action = #selector(checkboxStateChanged)
        
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
    
    @objc func checkboxStateChanged(_ sender: NSButton) {
        if sender.state == .on {
            undeafenOnClickDescriptionLabel.stringValue = "When deafened, clicking the stem or pressing the digital crown will undeafen and unmute you."
            
            UserDefaults.standard.setValue(false, forKey: "disable_click_to_undeafen")
        }
        else {
            undeafenOnClickDescriptionLabel.stringValue = "When deafened, clicking the stem or pressing the digital crown will not do anything."
            
            UserDefaults.standard.setValue(true, forKey: "disable_click_to_undeafen")
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

