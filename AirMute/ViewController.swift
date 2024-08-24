import Cocoa

class ViewController: NSViewController, NSTextFieldDelegate {
    @IBOutlet weak var clientIdTextField: NSTextField!
    @IBOutlet weak var clientSecretTextField: NSTextField!
    @IBOutlet weak var textFieldDescription: NSTextField!
    @IBOutlet weak var undeafenOnClickCheckbox: NSButton!
    @IBOutlet weak var undeafenOnClickDescriptionLabel: NSTextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        clientIdTextField.delegate = self
        clientSecretTextField.delegate = self
        undeafenOnClickCheckbox.target = self

        clientIdTextField.stringValue = UserDefaults.standard.string(forKey: "client_id") ?? ""
        clientSecretTextField.stringValue = UserDefaults.standard.string(forKey: "client_secret") ?? ""
        undeafenOnClickCheckbox.state = !UserDefaults.standard.bool(forKey: "disable_click_to_undeafen") ? .on : .off
        undeafenOnClickDescriptionLabel.stringValue = !UserDefaults.standard.bool(forKey: "disable_click_to_undeafen") ? "When deafened, clicking the stem will undeafen and unmute you." : "When deafened, clicking the stem will not do anything."
        
        undeafenOnClickCheckbox.action = #selector(checkboxStateChanged)
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
            undeafenOnClickDescriptionLabel.stringValue = "When deafened, clicking the stem will undeafen and unmute you."
            
            UserDefaults.standard.setValue(false, forKey: "disable_click_to_undeafen")
        }
        else {
            undeafenOnClickDescriptionLabel.stringValue = "When deafened, clicking the stem will not do anything."
            
            UserDefaults.standard.setValue(true, forKey: "disable_click_to_undeafen")
        }
    }
    
    override func viewWillDisappear() {
        UserDefaults.standard.setValue(clientIdTextField.stringValue, forKey: "client_id")
        UserDefaults.standard.setValue(clientSecretTextField.stringValue, forKey: "client_secret")
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

