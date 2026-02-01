/*
 MARK: - Live Activity Widget (Disabled)
 
 This entire file is commented out because it requires proper Live Activity entitlements
 and Widget Extension configuration. To enable Live Activities:
 1. Add the Live Activity capability to your widget extension
 2. Configure the entitlements properly
 3. Uncomment this code
 4. Uncomment SentinelWidgetLiveActivity() in SentinelWidgetBundle.swift
*/

/*
import WidgetKit
import SwiftUI
import ActivityKit

struct SentinelWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PriceActivityAttributes.self) { context in
            // Lock Screen UI
            LockScreenLiveActivityView(state: context.state, symbol: context.attributes.symbol)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading ) {
                    HStack {
                        // Icon
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .foregroundStyle(.blue)
                        Text(context.attributes.symbol)
                            .font(.headline)
                    }
                    .padding(.leading)
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing) {
                        Text(String(format: "$%.2f", context.state.price))
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(String(format: "%.2f%%", context.state.changePercent))
                            .formattedChange(isPositive: context.state.change > 0)
                    }
                    .padding(.trailing)
                }
                
                DynamicIslandExpandedRegion(.center) {
                    // Center content for expanded
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    // Sparkline or extra info could go here
                }
                
            } compactLeading: {
                Text(context.attributes.symbol)
                    .font(.caption2)
                    .fontWeight(.bold)
            } compactTrailing: {
                Text(String(format: "$%.2f", context.state.price))
                    .font(.caption2)
                    .foregroundStyle(context.state.change > 0 ? .green : .red)
            } minimal: {
                Image(systemName: context.state.change > 0 ? "arrow.up" : "arrow.down")
                    .foregroundStyle(context.state.change > 0 ? .green : .red)
            }
        }
    }
}

struct LockScreenLiveActivityView: View {
    let state: PriceActivityAttributes.ContentState
    let symbol: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .foregroundStyle(.blue)
                    Text(symbol)
                        .font(.headline)
                }
                Text("Live Price")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text(String(format: "$%.2f", state.price))
                    .font(.title)
                    .fontWeight(.bold)
                
                HStack(spacing: 4) {
                    Text(String(format: "%+.2f", state.change))
                    Text("(\(String(format: "%.2f", state.changePercent))%)")
                }
                .formattedChange(isPositive: state.change > 0)
            }
        }
        .padding()
        .activityBackgroundTint(Color.black.opacity(0.8))
    }
}

extension View {
    func formattedChange(isPositive: Bool) -> some View {
        self
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(isPositive ? .green : .red)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                (isPositive ? Color.green : Color.red).opacity(0.2)
            )
            .clipShape(Capsule())
    }
}
*/
