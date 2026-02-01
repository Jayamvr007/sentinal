import Foundation

/// Model for AI prediction response
struct Prediction: Codable, Identifiable {
    var id: String { date }
    let date: String
    let predicted_price: Double
    let change_percent: Double
    let confidence: Double
    
    var formattedPrice: String {
        String(format: "₹%.2f", predicted_price)
    }
    
    var formattedChange: String {
        let sign = change_percent >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.2f", change_percent))%"
    }
    
    var isPositive: Bool {
        change_percent >= 0
    }
}

/// Full prediction response from API
struct PredictionResponse: Codable {
    let symbol: String
    let current_price: Double
    let previous_close: Double
    let change_today: Double
    let change_percent_today: Double
    let predictions: [Prediction]
    let historical_prices: [HistoricalPrice]?
    let trend_summary: TrendSummary?
    let model_type: String
    let lookback_days: Int
    let last_updated: String
    let disclaimer: String
    
    var formattedCurrentPrice: String {
        String(format: "₹%.2f", current_price)
    }
    
    var formattedChangeToday: String {
        let sign = change_today >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.2f", change_today))"
    }
    
    var formattedChangePercent: String {
        let sign = change_percent_today >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.2f", change_percent_today))%"
    }
    
    var isPositive: Bool {
        change_percent_today >= 0
    }
}

/// Symbol list response
struct SymbolListResponse: Codable {
    let total: Int
    let symbols: [String]
}
