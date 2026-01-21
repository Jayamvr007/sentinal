import SwiftUI

/// Placeholder view for alerts management
struct AlertsView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "bell.badge")
                    .font(.system(size: 60))
                    .foregroundStyle(.secondary)
                
                Text("Alerts")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Configure custom alerts to notify you when market conditions match your criteria.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Button(action: {}) {
                    Label("Create Alert", systemImage: "plus")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 40)
                .padding(.top, 20)
            }
            .navigationTitle("Alerts")
        }
    }
}

#Preview {
    AlertsView()
}
