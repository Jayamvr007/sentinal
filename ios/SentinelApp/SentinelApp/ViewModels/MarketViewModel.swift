import Foundation
import Observation

/// ViewModel for market data management
@MainActor
@Observable
final class MarketViewModel {
    
    // MARK: - Properties
    
    private(set) var prices: [PriceData] = []
    private(set) var pricesBySector: [String: [PriceData]] = [:]
    private(set) var isLoading = true
    private(set) var error: String?
    
    private let webSocketManager: WebSocketManager
    private var updateTask: Task<Void, Never>?
    
    // MARK: - Computed Properties
    
    var connectionState: ConnectionState {
        webSocketManager.connectionState
    }
    
    var lastUpdate: Date? {
        webSocketManager.lastUpdate
    }
    
    var isConnected: Bool {
        webSocketManager.connectionState.isConnected
    }
    
    var gainersCount: Int {
        prices.filter { $0.changePercent > 0 }.count
    }
    
    var losersCount: Int {
        prices.filter { $0.changePercent < 0 }.count
    }
    
    /// Ordered sectors for display
    var orderedSectors: [String] {
        ["Technology", "Automotive", "Consumer", "Commodities", "Index"]
            .filter { pricesBySector[$0] != nil }
    }
    
    // MARK: - Initialization
    
    init(webSocketManager: WebSocketManager = WebSocketManager()) {
        self.webSocketManager = webSocketManager
    }
    
    // MARK: - Public Methods
    
    /// Start receiving price updates
    func startUpdates() {
        webSocketManager.connect()
        
        // Observe changes
        updateTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(100))
                self.updateFromManager()
            }
        }
    }
    
    /// Stop receiving price updates
    func stopUpdates() {
        updateTask?.cancel()
        updateTask = nil
        webSocketManager.disconnect()
    }
    
    /// Force reconnect
    func reconnect() {
        webSocketManager.reconnect()
    }
    
    /// Refresh data (pull to refresh)
    func refresh() async {
        webSocketManager.reconnect()
        try? await Task.sleep(for: .seconds(1))
    }
    
    // MARK: - Private Methods
    
    private func updateFromManager() {
        let newPrices = webSocketManager.sortedPrices
        if !newPrices.isEmpty {
            self.prices = newPrices
            self.pricesBySector = webSocketManager.pricesBySector
            self.isLoading = false
        }
    }
}
