/*
 MARK: - Price Activity Attributes (Disabled)
 
 This code is commented out because it requires a Widget Extension target.
 To enable Live Activities, uncomment this file after adding a Widget Extension.
*/

// import ActivityKit
import Foundation

/*
struct PriceActivityAttributes: ActivityAttributes, Sendable {
    public struct ContentState: Codable, Hashable, Sendable {
        // Dynamic state that changes over time
        var price: Double
        var change: Double
        var changePercent: Double
        var lastUpdated: Date
    }

    // Fixed non-changing properties about your activity
    var symbol: String
}
*/

// MARK: - Stub for compilation (when Live Activities are disabled)
struct PriceActivityAttributes {
    struct ContentState {
        var price: Double
        var change: Double
        var changePercent: Double
        var lastUpdated: Date
    }
    var symbol: String
}

