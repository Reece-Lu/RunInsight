//
//  RunWorkoutRecord.swift
//  RunInsight
//
//  Created by Codex on 2026-05-03.
//

import Foundation
import SwiftData

@Model
final class RunWorkoutRecord {
    @Attribute(.unique) var healthKitID: UUID
    var distanceMeters: Double
    var duration: TimeInterval
    var startDate: Date
    var endDate: Date
    var calories: Double?
    var averagePace: TimeInterval?
    var locationTypeRaw: String = RunLocationType.unknown.rawValue
    var locationTypeSourceRaw: String = RunLocationTypeSource.unknown.rawValue
    var indoorWorkoutRawValue: String?
    var hasRoute: Bool = false
    var sourceName: String?
    var metadataText: String = ""
    var importedAt: Date

    init(
        healthKitID: UUID,
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
        metadataText: String = "",
        importedAt: Date = Date()
    ) {
        self.healthKitID = healthKitID
        self.distanceMeters = distanceMeters
        self.duration = duration
        self.startDate = startDate
        self.endDate = endDate
        self.calories = calories
        self.averagePace = averagePace
        self.locationTypeRaw = locationType.rawValue
        self.locationTypeSourceRaw = locationTypeSource.rawValue
        self.indoorWorkoutRawValue = indoorWorkoutRawValue
        self.hasRoute = hasRoute
        self.sourceName = sourceName
        self.metadataText = metadataText
        self.importedAt = importedAt
    }

    convenience init(workout: RunWorkout) {
        self.init(
            healthKitID: workout.id,
            distanceMeters: workout.distanceMeters,
            duration: workout.duration,
            startDate: workout.startDate,
            endDate: workout.endDate,
            calories: workout.calories,
            averagePace: workout.averagePace,
            locationType: workout.locationType,
            locationTypeSource: workout.locationTypeSource,
            indoorWorkoutRawValue: workout.indoorWorkoutRawValue,
            hasRoute: workout.hasRoute,
            sourceName: workout.sourceName,
            metadataText: workout.metadataText
        )
    }

    var locationType: RunLocationType {
        RunLocationType(rawValue: locationTypeRaw) ?? .unknown
    }

    var locationTypeSource: RunLocationTypeSource {
        RunLocationTypeSource(rawValue: locationTypeSourceRaw) ?? .unknown
    }

    var runWorkout: RunWorkout {
        RunWorkout(
            id: healthKitID,
            distanceMeters: distanceMeters,
            duration: duration,
            startDate: startDate,
            endDate: endDate,
            calories: calories,
            averagePace: averagePace,
            locationType: locationType,
            locationTypeSource: locationTypeSource,
            indoorWorkoutRawValue: indoorWorkoutRawValue,
            hasRoute: hasRoute,
            sourceName: sourceName,
            metadataText: metadataText
        )
    }
}
