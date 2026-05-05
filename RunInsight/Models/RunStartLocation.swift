//
//  RunStartLocation.swift
//  RunInsight
//
//  Created by Codex on 2026-05-04.
//

import CoreLocation
import Foundation

struct RunStartLocation: Identifiable, Equatable {
    let id: UUID
    let date: Date
    let distanceMeters: Double
    let coordinate: CLLocationCoordinate2D

    static func == (lhs: RunStartLocation, rhs: RunStartLocation) -> Bool {
        lhs.id == rhs.id
            && lhs.date == rhs.date
            && lhs.distanceMeters == rhs.distanceMeters
            && lhs.coordinate.latitude == rhs.coordinate.latitude
            && lhs.coordinate.longitude == rhs.coordinate.longitude
    }
}
