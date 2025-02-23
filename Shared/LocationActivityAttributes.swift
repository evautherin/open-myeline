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
        
        static var updates: AsyncMapSequence<some AsyncSequence, LocationActivityAttributes.ContentState> {
            CLLocationUpdate.liveUpdates()
                .compactMap(\.location)
                .map(\.degrees)
                .map(LocationActivityAttributes.ContentState.init)
        }
    }
}

extension CLLocation {
    var degrees: (CLLocationDegrees, CLLocationDegrees) { (coordinate.latitude, coordinate.longitude) }
}


