import Foundation
import AppKit

class NumericTextField: NSTextField {
    private let numericStringRegex = try! Regex("^[0-9]+$")
    private var _value: String = ""
    
    override var stringValue: String {
        didSet {
            if !stringValue.isEmpty {
                if try! numericStringRegex.firstMatch(in: stringValue) != nil {
                    _value = stringValue
                }
                else {
                    stringValue = _value
                }
            }
        }
    }
    
    override func textDidChange(_ notification: Notification) {
        super.textDidChange(notification)
        
        if stringValue.isEmpty {
            _value = ""
            self.stringValue = ""
        }
        else if try! numericStringRegex.firstMatch(in: stringValue) == nil {
            stringValue = _value
        }
        else {
            _value = stringValue
        }
    }
}
