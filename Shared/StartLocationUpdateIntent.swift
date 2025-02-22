//
//  StartLocationUpdateIntent.swift
//  Myeline
//
//  Created by Etienne Vautherin on 19/02/2025.
//

import AppIntents
import ActivityKit

struct StartLocationUpdateIntent: AppIntent, LiveActivityIntent {
    static var title: LocalizedStringResource = "Start Location Updates"
    static var description = IntentDescription("Begin tracking location and start the Live Activity.")

    func perform() async throws -> some IntentResult {
        await LiveActivityManager.shared.startActivity()
        return .result()
    }
}
