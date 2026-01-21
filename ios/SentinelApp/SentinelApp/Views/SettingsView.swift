import SwiftUI

/// Placeholder view for settings
struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Connection") {
                    HStack {
                        Label("Server URL", systemImage: "server.rack")
                        Spacer()
                        Text("localhost:8000")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Label("Update Interval", systemImage: "clock")
                        Spacer()
                        Text("1 second")
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section("Notifications") {
                    Toggle(isOn: .constant(true)) {
                        Label("Push Notifications", systemImage: "bell")
                    }
                    
                    Toggle(isOn: .constant(false)) {
                        Label("Sound", systemImage: "speaker.wave.2")
                    }
                }
                
                Section("About") {
                    HStack {
                        Label("Version", systemImage: "info.circle")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                    
                    Link(destination: URL(string: "https://github.com")!) {
                        Label("View Source", systemImage: "chevron.left.forwardslash.chevron.right")
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
}
