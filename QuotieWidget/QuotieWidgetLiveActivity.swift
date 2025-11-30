//
//  QuotieWidgetLiveActivity.swift
//  QuotieWidget
//
//  Created by Andre Bradford on 11/19/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct QuotieWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct QuotieWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: QuotieWidgetAttributes.self) { context in
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

extension QuotieWidgetAttributes {
    fileprivate static var preview: QuotieWidgetAttributes {
        QuotieWidgetAttributes(name: "World")
    }
}

extension QuotieWidgetAttributes.ContentState {
    fileprivate static var smiley: QuotieWidgetAttributes.ContentState {
        QuotieWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: QuotieWidgetAttributes.ContentState {
         QuotieWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: QuotieWidgetAttributes.preview) {
   QuotieWidgetLiveActivity()
} contentStates: {
    QuotieWidgetAttributes.ContentState.smiley
    QuotieWidgetAttributes.ContentState.starEyes
}
