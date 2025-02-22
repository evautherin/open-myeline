//
//  StopLocationUpdateIntent.swift
//  Myeline
//
//  Created by Etienne Vautherin on 22/02/2025.
//

import AppIntents

struct StopLocationUpdateIntent: AppIntent {
    static var title: LocalizedStringResource = "Stop Location Updates"
    static var description = IntentDescription("Stop tracking location and end the Live Activity.")

    func perform() async throws -> some IntentResult {
        await LiveActivityManager.shared.stopActivity()
        return .result()
    }
}
