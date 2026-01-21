import Foundation

/// Real-time price data for a market symbol
struct PriceData: Codable, Identifiable, Equatable {
    let symbol: String
    let price: Double
    let previousClose: Double
    let change: Double
    let changePercent: Double
    let volume: Int
    let timestamp: String
    
    var id: String { symbol }
    
    /// True if price change is positive or zero
    var isPositive: Bool {
        changePercent >= 0
    }
    
    /// Formatted price string
    var formattedPrice: String {
        String(format: "$%.2f", price)
    }
    
    /// Formatted change with sign
    var formattedChange: String {
        let sign = change >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.2f", change))"
    }
    
    /// Formatted percentage change
    var formattedChangePercent: String {
        let sign = changePercent >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.2f", changePercent))%"
    }
    
    /// Formatted volume (e.g., 1.2M, 500K)
    var formattedVolume: String {
        if volume >= 1_000_000 {
            return String(format: "%.1fM", Double(volume) / 1_000_000)
        } else if volume >= 1_000 {
            return String(format: "%.0fK", Double(volume) / 1_000)
        }
        return "\(volume)"
    }
    
    enum CodingKeys: String, CodingKey {
        case symbol
        case price
        case previousClose = "previous_close"
        case change
        case changePercent = "change_percent"
        case volume
        case timestamp
    }
}

/// Symbol information
struct SymbolInfo: Codable, Identifiable {
    let symbol: String
    let name: String
    let sector: String
    let currentPrice: Double?
    
    var id: String { symbol }
    
    enum CodingKeys: String, CodingKey {
        case symbol
        case name
        case sector
        case currentPrice = "current_price"
    }
}

/// WebSocket message wrapper
struct WebSocketMessage: Codable {
    let type: String
    let data: MessageData
    let timestamp: String
    
    struct MessageData: Codable {
        let prices: [PriceData]?
        let status: String?
    }
}

/// Symbol metadata for display
enum SymbolMetadata {
    static let companyNames: [String: String] = [
        "AAPL": "Apple Inc.",
        "GOOGL": "Alphabet Inc.",
        "TSLA": "Tesla Inc.",
        "MSFT": "Microsoft Corp.",
        "AMZN": "Amazon.com Inc.",
        "NVDA": "NVIDIA Corp.",
        "META": "Meta Platforms",
        "SLV": "iShares Silver Trust",
        "GLD": "SPDR Gold Shares",
        "SPY": "S&P 500 ETF"
    ]
    
    static let sectors: [String: String] = [
        "AAPL": "Technology",
        "GOOGL": "Technology",
        "TSLA": "Automotive",
        "MSFT": "Technology",
        "AMZN": "Consumer",
        "NVDA": "Technology",
        "META": "Technology",
        "SLV": "Commodities",
        "GLD": "Commodities",
        "SPY": "Index"
    ]
    
    static let sectorIcons: [String: String] = [
        "Technology": "💻",
        "Automotive": "🚗",
        "Consumer": "🛒",
        "Commodities": "🪙",
        "Index": "📊"
    ]
    
    static func companyName(for symbol: String) -> String {
        companyNames[symbol] ?? symbol
    }
    
    static func sector(for symbol: String) -> String {
        sectors[symbol] ?? "Other"
    }
    
    static func sectorIcon(for symbol: String) -> String {
        let sector = sectors[symbol] ?? "Other"
        return sectorIcons[sector] ?? "📈"
    }
}
