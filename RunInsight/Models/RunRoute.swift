//
//  RunRoute.swift
//  RunInsight
//
//  Created by Codex on 2026-05-02.
//

import CoreLocation
import Foundation

struct RunRoute: Equatable {
    let locations: [CLLocation]

    var coordinates: [CLLocationCoordinate2D] {
        locations.map(\.coordinate)
    }

    static func == (lhs: RunRoute, rhs: RunRoute) -> Bool {
        lhs.locations.map(\.coordinate.latitude) == rhs.locations.map(\.coordinate.latitude)
            && lhs.locations.map(\.coordinate.longitude) == rhs.locations.map(\.coordinate.longitude)
            && lhs.locations.map(\.timestamp) == rhs.locations.map(\.timestamp)
    }
}
