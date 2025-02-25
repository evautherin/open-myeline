//
//  LocationActivityAttributes.swift
//  Myeline
//
//  Created by Etienne Vautherin on 19/02/2025.
//

import ActivityKit
import CoreLocation

struct LocationActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var latitude: Double?
        var longitude: Double?
        
        static var updates: AsyncMapSequence<some AsyncSequence, ContentState> {
            CLLocationUpdate.liveUpdates()
                .compactMap(\.location)
                .map(\.degrees)
                .map(LocationActivityAttributes.ContentState.init)
        }
    }
    
    // Create the initial state with nil location values.
    static var initialState: ContentState { ContentState(latitude: nil, longitude: nil) }
}

extension CLLocation {
    var degrees: (CLLocationDegrees, CLLocationDegrees) { (coordinate.latitude, coordinate.longitude) }
}

extension ActivityContent where State == LocationActivityAttributes.ContentState {
    static var updates: AsyncMapSequence<some AsyncSequence, ActivityContent> {
        State.updates
            .map {
                ActivityContent(
                    state: $0,
                    staleDate: .none,
                    relevanceScore: 0.0
                )
            }
    }
}

extension Activity where Attributes == LocationActivityAttributes {
    
    func firstActiveState() async -> ActivityState? {
        await activityStateUpdates.first(where: { $0 == .active })
    }
    
    func updateContentState() async -> Task<Void, Never>? {
        guard activityState == .active else { return .none }
        
        // Start an async Task to process location updates.
        return Task {
            do {
                for try await updatedContent in ActivityContent.updates {
                    
                    #if DEBUG
                    let state = updatedContent.state
                    let latitude = state.latitude?.description ?? "--"
                    let longitude = state.longitude?.description ?? "--"
                    print("Updated content \(latitude)  \(longitude))")
                    #endif
                    
                    // Update the Live Activity.
                    await update(updatedContent)
                }
            } catch {
                print("Error receiving location updates: \(error)")
            }
        }
    }
}
