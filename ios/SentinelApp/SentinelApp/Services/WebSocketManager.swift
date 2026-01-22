import Foundation
import Observation

// MARK: - Notification Names
extension Notification.Name {
    static let alertTriggered = Notification.Name("alertTriggered")
}

/// Connection state for WebSocket
enum ConnectionState: Equatable, Sendable {
    case connecting
    case connected
    case disconnected
    case reconnecting(attempt: Int)
    
    var displayText: String {
        switch self {
        case .connecting:
            return "Connecting..."
        case .connected:
            return "Live"
        case .disconnected:
            return "Disconnected"
        case .reconnecting(let attempt):
            return "Reconnecting (\(attempt))..."
        }
    }
    
    var isConnected: Bool {
        self == .connected
    }
}

/// WebSocket manager for real-time price streaming
@MainActor
@Observable
final class WebSocketManager {
    
    // MARK: - Properties
    
    private(set) var connectionState: ConnectionState = .disconnected
    private(set) var prices: [String: PriceData] = [:]
    private(set) var lastUpdate: Date?
    
    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession
    private var reconnectAttempt = 0
    private var reconnectTask: Task<Void, Never>?
    
    private let url: URL
    private let maxReconnectAttempts = 10
    private let baseReconnectDelay: TimeInterval = 1.0
    private let maxReconnectDelay: TimeInterval = 30.0
    
    // MARK: - Initialization
    
    init(url: URL = URL(string: "ws://192.168.29.252:8000/price/stream")!) {
        self.url = url
        self.urlSession = URLSession(configuration: .default)
    }
    
    // MARK: - Public Methods
    
    /// Connect to WebSocket server
    func connect() {
        guard connectionState != .connected else { return }
        
        connectionState = .connecting
        
        webSocketTask = urlSession.webSocketTask(with: url)
        webSocketTask?.resume()
        
        // Start listening for messages
        listenForMessages()
        
        // Mark as connected after successful connection
        Task {
            try? await Task.sleep(for: .milliseconds(500))
            if self.webSocketTask?.state == .running {
                self.connectionState = .connected
                self.reconnectAttempt = 0
            }
        }
    }
    
    /// Disconnect from WebSocket server
    func disconnect() {
        reconnectTask?.cancel()
        reconnectTask = nil
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        connectionState = .disconnected
    }
    
    /// Force reconnect
    func reconnect() {
        disconnect()
        reconnectAttempt = 0
        connect()
    }
    
    // MARK: - Private Methods
    
    private func listenForMessages() {
        let task = webSocketTask
        task?.receive { [weak self] result in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                switch result {
                case .success(let message):
                    self.handleMessage(message)
                    // Continue listening
                    self.listenForMessages()
                    
                case .failure(let error):
                    print("[WS] Error receiving message: \(error)")
                    self.handleDisconnection()
                }
            }
        }
    }
    
    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            parseMessage(text)
        case .data(let data):
            if let text = String(data: data, encoding: .utf8) {
                parseMessage(text)
            }
        @unknown default:
            break
        }
    }
    
    private func parseMessage(_ text: String) {
        guard let data = text.data(using: .utf8) else { return }
        
        do {
            let message = try JSONDecoder().decode(WebSocketMessage.self, from: data)
            
            switch message.type {
            case "price_update", "initial_data":
                if let newPrices = message.data.prices {
                    for price in newPrices {
                        self.prices[price.symbol] = price
                    }
                    self.lastUpdate = Date()
                }
            case "heartbeat":
                // Keep-alive, no action needed
                break
            case "alert_triggered":
                // Post notification for alert triggered
                print("[WS] Alert triggered: \(message.data)")
                NotificationCenter.default.post(
                    name: .alertTriggered,
                    object: nil,
                    userInfo: ["data": message.data]
                )
            default:
                print("[WS] Unknown message type: \(message.type)")
            }
        } catch {
            print("[WS] Error parsing message: \(error)")
        }
    }
    
    private func handleDisconnection() {
        connectionState = .disconnected
        webSocketTask = nil
        
        // Attempt reconnection with exponential backoff
        guard reconnectAttempt < maxReconnectAttempts else {
            print("[WS] Max reconnect attempts reached")
            return
        }
        
        reconnectAttempt += 1
        let delay = min(
            baseReconnectDelay * pow(2, Double(reconnectAttempt - 1)),
            maxReconnectDelay
        )
        
        connectionState = .reconnecting(attempt: reconnectAttempt)
        print("[WS] Reconnecting in \(delay)s (attempt \(reconnectAttempt))")
        
        reconnectTask = Task {
            try? await Task.sleep(for: .seconds(delay))
            if !Task.isCancelled {
                self.connect()
            }
        }
    }
    
    /// Get sorted list of prices
    var sortedPrices: [PriceData] {
        prices.values.sorted { $0.symbol < $1.symbol }
    }
    
    /// Get prices grouped by sector
    var pricesBySector: [String: [PriceData]] {
        Dictionary(grouping: prices.values) { price in
            SymbolMetadata.sector(for: price.symbol)
        }
    }
}
