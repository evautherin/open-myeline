//
//  MyelineApp.swift
//  Myeline
//
//  Created by Etienne Vautherin on 19/02/2025.
//

import SwiftUI

@main
struct MyelineApp: App {
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            let manager = LiveActivityManager.shared
            
            if newPhase == .background {
                // Perform cleanup when all scenes within
                // Myeline go to the background.
                Task {
                    await LiveActivityManager.shared.createAlwaysSession()
                }
            }
            if newPhase == .active {
                manager.invalidateAlwaysSession()
            }
        }
    }
}
