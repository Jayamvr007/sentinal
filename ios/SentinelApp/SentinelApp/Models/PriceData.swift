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
    
    /// Formatted price string (Indian Rupees)
    var formattedPrice: String {
        String(format: "₹%.2f", price)
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

/// Symbol metadata for NIFTY 50 Indian stocks
enum SymbolMetadata {
    static let companyNames: [String: String] = [
        "RELIANCE": "Reliance Industries",
        "TCS": "Tata Consultancy Services",
        "HDFCBANK": "HDFC Bank Ltd.",
        "INFY": "Infosys Ltd.",
        "ICICIBANK": "ICICI Bank Ltd.",
        "HINDUNILVR": "Hindustan Unilever",
        "ITC": "ITC Ltd.",
        "SBIN": "State Bank of India",
        "BHARTIARTL": "Bharti Airtel Ltd.",
        "KOTAKBANK": "Kotak Mahindra Bank"
    ]
    
    static let sectors: [String: String] = [
        "RELIANCE": "Energy",
        "TCS": "Technology",
        "HDFCBANK": "Finance",
        "INFY": "Technology",
        "ICICIBANK": "Finance",
        "HINDUNILVR": "Consumer",
        "ITC": "Consumer",
        "SBIN": "Finance",
        "BHARTIARTL": "Telecom",
        "KOTAKBANK": "Finance"
    ]
    
    static let sectorIcons: [String: String] = [
        "Technology": "💻",
        "Finance": "🏦",
        "Consumer": "🛒",
        "Energy": "⚡",
        "Telecom": "📱"
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
