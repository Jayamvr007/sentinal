//
//  SentinelWidgetLiveActivity.swift
//  SentinelWidget
//
//  Created by Jayam Verma on 23/01/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct SentinelWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct SentinelWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SentinelWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension SentinelWidgetAttributes {
    fileprivate static var preview: SentinelWidgetAttributes {
        SentinelWidgetAttributes(name: "World")
    }
}

extension SentinelWidgetAttributes.ContentState {
    fileprivate static var smiley: SentinelWidgetAttributes.ContentState {
        SentinelWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: SentinelWidgetAttributes.ContentState {
         SentinelWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: SentinelWidgetAttributes.preview) {
   SentinelWidgetLiveActivity()
} contentStates: {
    SentinelWidgetAttributes.ContentState.smiley
    SentinelWidgetAttributes.ContentState.starEyes
}
