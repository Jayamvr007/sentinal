import SwiftUI

/// Connection status indicator view
struct ConnectionStatusView: View {
    let state: ConnectionState
    let lastUpdate: Date?
    let onReconnect: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            // Status indicator
            HStack(spacing: 6) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                    .overlay {
                        if state.isConnected || state == .connecting {
                            Circle()
                                .stroke(statusColor.opacity(0.5), lineWidth: 2)
                                .scaleEffect(1.5)
                                .opacity(0.8)
                                .animation(
                                    .easeInOut(duration: 1).repeatForever(autoreverses: true),
                                    value: state
                                )
                        }
                    }
                
                Text(state.displayText)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }
            
            // Last update time
            if let lastUpdate, state.isConnected {
                Text(lastUpdate, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            
            // Reconnect button
            if state == .disconnected {
                Button("Retry", action: onReconnect)
                    .font(.caption)
                    .foregroundStyle(.blue)
            }
        }
    }
    
    private var statusColor: Color {
        switch state {
        case .connected:
            return .green
        case .connecting, .reconnecting:
            return .orange
        case .disconnected:
            return .red
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ConnectionStatusView(
            state: .connected,
            lastUpdate: Date(),
            onReconnect: {}
        )
        
        ConnectionStatusView(
            state: .connecting,
            lastUpdate: nil,
            onReconnect: {}
        )
        
        ConnectionStatusView(
            state: .disconnected,
            lastUpdate: nil,
            onReconnect: {}
        )
    }
    .padding()
}
