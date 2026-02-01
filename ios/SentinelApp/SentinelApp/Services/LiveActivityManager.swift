/*
 MARK: - Live Activity Manager (Disabled)
 
 This code is commented out because it requires a Widget Extension target.
 To enable Live Activities:
 1. Add a Widget Extension to the Xcode project
 2. Uncomment this code
 3. Uncomment the PriceActivityAttributes.swift file
 4. Uncomment Live Activity code in WebSocketManager and PriceCardView
*/

import Foundation
// import ActivityKit  // Requires Widget Extension

/*
@MainActor
final class LiveActivityManager: ObservableObject {
    static let shared = LiveActivityManager()
    
    @Published var activity: Activity<PriceActivityAttributes>?
    
    private init() {}
    
    /// Start a new Live Activity for a symbol
    func start(symbol: String, price: Double, change: Double, changePercent: Double) {
        // End existing activity if any
        if activity != nil {
            Task {
                await end()
            }
        }
        
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("[LiveActivity] Activities not enabled")
            return
        }
        
        let attributes = PriceActivityAttributes(symbol: symbol)
        let contentState = PriceActivityAttributes.ContentState(
            price: price,
            change: change,
            changePercent: changePercent,
            lastUpdated: Date()
        )
        
        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: contentState, staleDate: nil)
            )
            self.activity = activity
            print("[LiveActivity] Started for \(symbol)")
        } catch {
            print("[LiveActivity] Error starting: \(error.localizedDescription)")
        }
    }
    
    /// Update the current Live Activity
    func update(price: Double, change: Double, changePercent: Double) async {
        guard let activity = activity else { return }
        
        let contentState = PriceActivityAttributes.ContentState(
            price: price,
            change: change,
            changePercent: changePercent,
            lastUpdated: Date()
        )
        
        await activity.update(.init(state: contentState, staleDate: nil))
        print("[LiveActivity] Updated price: \(price)")
    }
    
    /// End the current Live Activity
    func end() async {
        guard let activity = activity else { return }
        
        await activity.end(nil, dismissalPolicy: .immediate)
        self.activity = nil
        print("[LiveActivity] Ended")
    }
}
*/

// MARK: - Stub for compilation (when Live Activities are disabled)
@MainActor
final class LiveActivityManager: ObservableObject {
    static let shared = LiveActivityManager()
    @Published var activity: AnyObject? = nil
    private init() {}
    func start(symbol: String, price: Double, change: Double, changePercent: Double) {}
    func update(price: Double, change: Double, changePercent: Double) async {}
    func end() async {}
}

