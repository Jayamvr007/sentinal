import SwiftUI

/// Main content view with tab navigation
struct ContentView: View {
    var body: some View {
        TabView {
            MarketView()
                .tabItem {
                    Label("Market", systemImage: "chart.line.uptrend.xyaxis")
                }
            
            AlertsView()
                .tabItem {
                    Label("Alerts", systemImage: "bell.badge")
                }
            
            PredictionView()
                .tabItem {
                    Label("AI Insights", systemImage: "brain.head.profile")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
    }
}

#Preview {
    ContentView()
}
