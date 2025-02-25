//
//  LiveActivityManager.swift
//  Myeline
//
//  Created by Etienne Vautherin on 19/02/2025.
//

import CoreLocation
import ActivityKit

#if targetEnvironment(simulator)
import SwiftLocation
#endif

final class LiveActivityManager {
    static let shared = LiveActivityManager()
    
    private var locationTask: Task<Void, Never>?
    private var activity: Activity<LocationActivityAttributes>?
    private var whenInUseSession: CLServiceSession?
    private var alwaysSession: CLServiceSession?

    private init() {}

    /// Starts the Live Activity and begins tracking location.
    func startActivity() async {
        let initialContent = ActivityContent(
            state: LocationActivityAttributes.initialState,
            staleDate: nil,
            relevanceScore: 0.0
        )
        
        do {
            // Start the Live Activity using the ActivityContent-based API.
            activity = try Activity.request(
                attributes: LocationActivityAttributes(),
                content: initialContent,
                pushType: nil
            )
        } catch {
            print("Error starting Live Activity: \(error)")
            return
        }
        guard let activity = activity else { return }
        
        _ = await activity.firstActiveState()
        
        whenInUseSession = CLServiceSession(authorization: .whenInUse)
        guard let whenInUseSession = whenInUseSession else { return }
        do {
            print("Waiting for whenInUse authorization")
            _ = try await whenInUseSession.diagnostics.first(where: { !$0.authorizationRequestInProgress })
            print("Request completed")
        } catch {
            print("Error in CLServiceSession diagnotics: \(error)")
            return
        }
        
        locationTask = await activity.updateContentState()
    }

    /// Stops the Live Activity and cancels location tracking.
    func stopActivity() async {
        // Cancel the location update task.
        locationTask?.cancel()
        locationTask = nil
        alwaysSession?.invalidate()
        alwaysSession = nil
        whenInUseSession?.invalidate()
        whenInUseSession = nil
        
        // End the Live Activity with final content (resetting location to nil).
        if let currentActivity = activity {
            let finalState = LocationActivityAttributes.ContentState(latitude: nil, longitude: nil)
            let finalContent = ActivityContent(state: finalState, staleDate: nil, relevanceScore: 0.0)
            await currentActivity.end(finalContent, dismissalPolicy: .immediate)
        }
    }
    
    func createAlwaysSession() async {
        guard (whenInUseSession != nil) else { return }

        #if targetEnvironment(simulator)
        do {
            try await Location().requestPermission(.always)
        } catch {
            print("Error in requestPermission: \(error)")
            return
        }
        #endif
        
        print("createAlwaysSession")
        alwaysSession = CLServiceSession(authorization: .always) //, fullAccuracyPurposeKey: "monitor")
        guard let alwaysSession = alwaysSession else { return }
            
        #if DEBUG
        Task {
            do {
                for try await diagnostic in alwaysSession.diagnostics {
                    if (diagnostic.authorizationDenied) {
                        print("** authorizationDenied")
                    }
                    if (diagnostic.authorizationDeniedGlobally) {
                        print("** authorizationDeniedGlobally")
                    }
                    if (diagnostic.authorizationRestricted) {
                        print("** authorizationRestricted")
                    }
                    if (diagnostic.insufficientlyInUse) {
                        print("** insufficientlyInUse")
                    }
                    if (diagnostic.serviceSessionRequired) {
                        print("** serviceSessionRequired")
                    }
                    if (diagnostic.authorizationRequestInProgress) {
                        print("** authorizationRequestInProgress")
                    }
                    if (diagnostic.fullAccuracyDenied) {
                        print("** fullAccuracyDenied")
                    }
                    if (diagnostic.alwaysAuthorizationDenied) {
                        print("** alwaysAuthorizationDenied")
                    }
                }
            } catch {
                print("Error in CLServiceSession diagnotics: \(error)")
                return
            }
        }
        #endif
    }
    
    func invalidateAlwaysSession() {
        print("invalidateAlwaysSession")
        alwaysSession?.invalidate()
    }
}
