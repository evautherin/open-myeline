//
//  LiveActivityManager.swift
//  Myeline
//
//  Created by Etienne Vautherin on 19/02/2025.
//

import Foundation
import ActivityKit
import CoreLocation

final class LiveActivityManager {
    static let shared = LiveActivityManager()
    
    private var locationTask: Task<Void, Never>?
    private var activity: Activity<LocationActivityAttributes>? = nil
    
    private init() {}

    /// Starts the Live Activity and begins tracking location.
    func startActivity() async {
        // Create the initial state with nil location values.
        let initialState = LocationActivityAttributes.ContentState(latitude: nil, longitude: nil)
        let initialContent = ActivityContent(state: initialState, staleDate: nil, relevanceScore: 0.0)
        
        do {
            // Start the Live Activity using the new ActivityContent-based API.
            activity = try Activity.request(
                attributes: LocationActivityAttributes(),
                content: initialContent,
                pushType: nil
            )
        } catch {
            print("Error starting Live Activity: \(error)")
            return
        }
        
        // Start an async Task to process location updates.
        locationTask = Task {
            do {
                for try await update in CLLocationUpdate.liveUpdates() {
                    // Extract the optional location.
                    let location = try update.location
                    let latitude = location?.coordinate.latitude
                    let longitude = location?.coordinate.longitude
                    
                    // Prepare the updated content.
                    let newState = LocationActivityAttributes.ContentState(latitude: latitude, longitude: longitude)
                    let updatedContent = ActivityContent(state: newState, staleDate: nil, relevanceScore: 0.0)
                    
                    // Update the Live Activity.
                    await activity?.update(updatedContent)
                }
            } catch {
                print("Error receiving location updates: \(error)")
            }
        }
    }

    /// Stops the Live Activity and cancels location tracking.
    func stopActivity() async {
        // Cancel the location update task.
        locationTask?.cancel()
        
        // End the Live Activity with final content (resetting location to nil).
        if let currentActivity = activity {
            let finalState = LocationActivityAttributes.ContentState(latitude: nil, longitude: nil)
            let finalContent = ActivityContent(state: finalState, staleDate: nil, relevanceScore: 0.0)
            await currentActivity.end(finalContent, dismissalPolicy: .immediate)
        }
    }
}
