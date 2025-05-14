import Foundation

let filePath = FileManager.default.homeDirectoryForCurrentUser.appending(path: "/Library/LaunchAgents/AirMute.plist")

func launchOnStartupStateChanged(to isOn: Bool) {
    if isOn {
        let plist: NSDictionary = [
            "Label": "AirMute",
            "AssociatedBundleIdentifiers": Bundle.main.bundleIdentifier!,
            "ProgramArguments": ["open", Bundle.main.bundlePath],
            "RunAtLoad": true,
            "AbandonProcessGroup": true
        ]
        if FileManager.default.createFile(atPath: filePath.path(), contents: nil) {
            try? plist.write(to: filePath)
        }
    }
    else {
        let filePath = FileManager.default.homeDirectoryForCurrentUser.appending(path: "/Library/LaunchAgents/AirMute.plist")
        try? FileManager.default.removeItem(at: filePath)
    }
}
