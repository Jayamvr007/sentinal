import Foundation

/// Represents a price alert
struct Alert: Codable, Identifiable {
    let id: String
    let symbol: String
    let condition: String
    let targetPrice: Double
    let isTriggered: Bool
    let isActive: Bool
    let createdAt: Date
    let triggeredAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case symbol
        case condition
        case targetPrice = "target_price"
        case isTriggered = "is_triggered"
        case isActive = "is_active"
        case createdAt = "created_at"
        case triggeredAt = "triggered_at"
    }
    
    /// Human-readable condition text
    var conditionText: String {
        condition == "above" ? "↗ Above" : "↘ Below"
    }
}

/// Request body for creating a new alert
struct AlertCreate: Codable {
    let symbol: String
    let condition: String
    let targetPrice: Double
    
    enum CodingKeys: String, CodingKey {
        case symbol
        case condition
        case targetPrice = "target_price"
    }
}
