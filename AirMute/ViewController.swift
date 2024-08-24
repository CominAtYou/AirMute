import Cocoa

class ViewController: NSViewController, NSTextFieldDelegate {
    @IBOutlet weak var clientIdTextField: NSTextField!
    @IBOutlet weak var clientSecretTextField: NSTextField!
    @IBOutlet weak var undeafenOnClickCheckbox: NSButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        clientIdTextField.delegate = self
        clientSecretTextField.delegate = self
        undeafenOnClickCheckbox.target = self

        clientIdTextField.stringValue = UserDefaults.standard.string(forKey: "client_id") ?? ""
        clientSecretTextField.stringValue = UserDefaults.standard.string(forKey: "client_secret") ?? ""
        undeafenOnClickCheckbox.state = !UserDefaults.standard.bool(forKey: "disable_click_to_undeafen") ? .on : .off
        
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
        UserDefaults.standard.setValue(sender.state == .on ? false : true, forKey: "disable_click_to_undeafen")
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

