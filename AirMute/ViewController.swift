import AppKit

import SwiftUI

class ViewController: NSHostingController<SettingsView> {
    required init?(coder: NSCoder) {
        super.init(coder: coder, rootView: SettingsView())
        self.sizingOptions = .intrinsicContentSize
    }
}
