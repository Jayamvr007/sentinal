import SwiftUI

/// Individual price card component
struct PriceCardView: View {
    let price: PriceData
    
    @State private var flash: FlashDirection?
    @State private var previousPrice: Double = 0
    
    private enum FlashDirection {
        case up, down
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(price.symbol)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                        
                        Text(SymbolMetadata.sectorIcon(for: price.symbol))
                            .font(.callout)
                    }
                    
                    Text(SymbolMetadata.companyName(for: price.symbol))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Change badge
                Text(price.formattedChangePercent)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(price.isPositive ? .green : .red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        (price.isPositive ? Color.green : Color.red)
                            .opacity(0.15)
                    )
                    .clipShape(Capsule())
            }
            
            // Price
            VStack(alignment: .leading, spacing: 4) {
                Text(price.formattedPrice)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                HStack(spacing: 8) {
                    Text(price.formattedChange)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(price.isPositive ? .green : .red)
                    
                    Text("vs prev close")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            
            // Footer stats
            HStack {
                HStack(spacing: 4) {
                    Text("Vol:")
                        .foregroundStyle(.tertiary)
                    Text(price.formattedVolume)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Text("Prev:")
                        .foregroundStyle(.tertiary)
                    Text(String(format: "$%.2f", price.previousClose))
                        .foregroundStyle(.secondary)
                }
            }
            .font(.caption)
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 16)
            .fill(.ultraThinMaterial)
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                .stroke(flashBorderColor, lineWidth: flash != nil ? 2 : 0)
            }
        }
        .onChange(of: price.price) { oldValue, newValue in
            if oldValue != newValue && previousPrice != 0 {
                withAnimation(.easeInOut(duration: 0.3)) {
                    flash = newValue > oldValue ? .up : .down
                }
                
                Task {
                    try? await Task.sleep(for: .milliseconds(500))
                    withAnimation {
                        flash = nil
                    }
                }
            }
            previousPrice = newValue
        }
        .onAppear {
            previousPrice = price.price
        }
        // MARK: - Live Activity Context Menu (Disabled)
        // Uncomment when Widget Extension is set up
        /*
        .contextMenu {
            Button {
                let manager = LiveActivityManager.shared
                if manager.activity?.attributes.symbol == price.symbol {
                    Task { await manager.end() }
                } else {
                    manager.start(
                        symbol: price.symbol,
                        price: price.price,
                        change: price.change,
                        changePercent: price.changePercent
                    )
                }
            } label: {
                if LiveActivityManager.shared.activity?.attributes.symbol == price.symbol {
                    Label("Stop Tracking", systemImage: "stop.circle")
                } else {
                    Label("Track Activity", systemImage: "clock.arrow.circlepath")
                }
            }
        }
        */
    }
    
    private var flashBorderColor: Color {
        switch flash {
        case .up:
            return .green.opacity(0.6)
        case .down:
            return .red.opacity(0.6)
        case .none:
            return .clear
        }
    }
}

#Preview {
    PriceCardView(price: PriceData(
        symbol: "AAPL",
        price: 175.50,
        previousClose: 174.00,
        change: 1.50,
        changePercent: 0.86,
        volume: 52_340_000,
        timestamp: "2024-01-15T10:30:00Z"
    ))
    .padding()
    .background(Color(.systemBackground))
}
