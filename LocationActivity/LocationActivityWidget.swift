//
//  LocationActivityWidget.swift
//  LocationActivity
//
//  Created by Etienne Vautherin on 19/02/2025.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct LocationActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LocationActivityAttributes.self) { context in
            // Lock screen/banner view.
            VStack {
                if let latitude = context.state.latitude, let longitude = context.state.longitude {
                    Text("Latitude: \(latitude)")
                    Text("Longitude: \(longitude)")
                } else {
                    Text("No Location Available")
                }
            }
            .activityBackgroundTint(.blue)
            .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded regions.
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.state.latitude != nil ? "Lat: \(context.state.latitude!)" : "Lat: --")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.longitude != nil ? "Long: \(context.state.longitude!)" : "Long: --")
                }
            } compactLeading: {
                Text("Loc")
            } compactTrailing: {
                Text("...")
            } minimal: {
                Text("Loc")
            }
        }
    }
}
