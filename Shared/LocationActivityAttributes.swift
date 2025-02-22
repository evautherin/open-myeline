//
//  LocationActivityAttributes.swift
//  Myeline
//
//  Created by Etienne Vautherin on 19/02/2025.
//

import ActivityKit
import Foundation

struct LocationActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var latitude: Double?
        var longitude: Double?
    }
}

