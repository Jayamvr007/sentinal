import SwiftUI

/// Market price list view with sector grouping
struct MarketView: View {
    @State private var viewModel = MarketViewModel()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Stats bar
                    statsBar
                    
                    // Prices list
                    if viewModel.isLoading && viewModel.prices.isEmpty {
                        loadingView
                    } else {
                        priceList
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Market")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ConnectionStatusView(
                        state: viewModel.connectionState,
                        lastUpdate: viewModel.lastUpdate,
                        onReconnect: viewModel.reconnect
                    )
                }
            }
            .refreshable {
                await viewModel.refresh()
            }
        }
        .onAppear {
            viewModel.startUpdates()
        }
        .onDisappear {
            viewModel.stopUpdates()
        }
    }
    
    // MARK: - Subviews
    
    private var statsBar: some View {
        HStack(spacing: 0) {
            statItem(value: "\(viewModel.prices.count)", label: "Symbols")
            Divider().frame(height: 32)
            statItem(value: "\(viewModel.gainersCount)", label: "Gainers", color: .green)
            Divider().frame(height: 32)
            statItem(value: "\(viewModel.losersCount)", label: "Losers", color: .red)
            Divider().frame(height: 32)
            statItem(value: viewModel.isConnected ? "1s" : "--", label: "Update")
        }
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    private func statItem(value: String, label: String, color: Color = .primary) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var loadingView: some View {
        VStack(spacing: 12) {
            ForEach(0..<4, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .frame(height: 140)
            }
        }
        .redacted(reason: .placeholder)
    }
    
    private var priceList: some View {
        LazyVStack(spacing: 12) {
            ForEach(viewModel.prices) { price in
                PriceCardView(price: price)
            }
        }
    }
}

#Preview {
    MarketView()
}
