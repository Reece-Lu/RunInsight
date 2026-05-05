//
//  RunWorkout.swift
//  RunInsight
//
//  Created by Codex on 2026-05-02.
//

import Foundation

struct RunWorkout: Identifiable, Equatable {
    let id: UUID
    let distanceMeters: Double
    let duration: TimeInterval
    let startDate: Date
    let endDate: Date
    let calories: Double?
    let averagePace: TimeInterval?
    let locationType: RunLocationType
    let locationTypeSource: RunLocationTypeSource
    let indoorWorkoutRawValue: String?
    let hasRoute: Bool
    let sourceName: String?
    let metadataText: String

    init(
        id: UUID,
        distanceMeters: Double,
        duration: TimeInterval,
        startDate: Date,
        endDate: Date,
        calories: Double?,
        averagePace: TimeInterval?,
        locationType: RunLocationType = .unknown,
        locationTypeSource: RunLocationTypeSource = .unknown,
        indoorWorkoutRawValue: String? = nil,
        hasRoute: Bool = false,
        sourceName: String? = nil,
        metadataText: String = ""
    ) {
        self.id = id
        self.distanceMeters = distanceMeters
        self.duration = duration
        self.startDate = startDate
        self.endDate = endDate
        self.calories = calories
        self.averagePace = averagePace
        self.locationType = locationType
        self.locationTypeSource = locationTypeSource
        self.indoorWorkoutRawValue = indoorWorkoutRawValue
        self.hasRoute = hasRoute
        self.sourceName = sourceName
        self.metadataText = metadataText
    }
}
