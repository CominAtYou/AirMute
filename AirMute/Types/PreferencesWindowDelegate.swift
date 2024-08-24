import Foundation
import AppKit

class PreferencesWindowDelegate: NSObject, NSWindowDelegate {
    var isOpen = false
    
    func windowWillClose(_ notification: Notification) {
        self.isOpen = false
    }
}
