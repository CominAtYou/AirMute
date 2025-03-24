import SwiftUI

struct SettingsView: View {
    @AppStorage("client_id") private var clientId = ""
    @AppStorage("client_secret") private var clientSecret = ""
    @AppStorage("click_to_undeafen") private var clickToUndeafen = true
    @AppStorage("launch_on_startup") private var launchOnStartup = false
    
    var body: some View {
        VStack {
            Form {
                Section {
                    TextField(text: $clientId) {
                        Text("Client ID")
                    }
                    
                    TextField(text: $clientSecret) {
                        Text("Client Secret")
                    }
                } footer: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            if #available(macOS 15, *) {
                                HStack(spacing: 1) {
                                    Text("You can obtain a Client ID and secret from the ")
                                    Text("[Discord Developer Portal](https://discord.com/developers/applications).")
                                        .pointerStyle(.link)
                                }
                            }
                            else {
                                Text("You can obtain a Client ID and secret from the [Discord Developer Portal](https://discord.com/developers/applications).")
                            }
                            
                            Text("Changes to the above values will require you to relaunch the app.")
                        }
                        .multilineTextAlignment(.leading)
                        .font(.system(size: 11.5))
                        .foregroundStyle(Color(nsColor: .secondaryLabelColor))
                        Spacer()
                    }
                    .frame(idealWidth: .infinity, maxWidth: .infinity)
                    .padding(.leading, 11)
                }
                
                Section {
                    Toggle(isOn: $clickToUndeafen) {
                        VStack(alignment: .leading, spacing: 2.5) {
                            Text("Click to Undeafen")
                            Text(clickToUndeafen ? "When deafened, clicking the stem or pressing the digital crown will undeafen and unmute you." : "When deafened, clicking the stem or pressing the digital crown will not do anything." )
                                .font(.system(size: 10.5))
                                .opacity(0.5)
                            
                        }
                    }
                    
                    Toggle(isOn: $launchOnStartup) {
                        Text("Launch on Startup")
                    }
                }
                
            }
            .formStyle(.grouped)
            
            Spacer()
            Text("AirMute \(Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String) (\(Bundle.main.infoDictionary!["CFBundleVersion"] as! String))")
                .padding(.bottom, 12)
                .foregroundStyle(Color(nsColor: .tertiaryLabelColor))
                .font(.system(size: 11))
        }
        .onChange(of: launchOnStartup) {
            launchOnStartupStateChanged(to: launchOnStartup)
        }
    }
}

#Preview {
    SettingsView()
}
