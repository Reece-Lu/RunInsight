//
//  HealthKitManager.swift
//  RunInsight
//
//  Created by Codex on 2026-05-02.
//

import CoreLocation
import Foundation
import HealthKit

enum HealthKitError: LocalizedError {
    case healthDataUnavailable
    case workoutTypeUnavailable

    var errorDescription: String? {
        switch self {
        case .healthDataUnavailable:
            "健康数据不可用".localized
        case .workoutTypeUnavailable:
            "运动数据不可用".localized
        }
    }
}

final class HealthKitManager {
    private let healthStore: HKHealthStore

    init(healthStore: HKHealthStore = HKHealthStore()) {
        self.healthStore = healthStore
    }

    func requestRunningWorkoutPermission() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.healthDataUnavailable
        }

        let workoutType = HKObjectType.workoutType()
        let routeType = HKSeriesType.workoutRoute()
        let readTypes = Set<HKObjectType>([workoutType, routeType] + Self.performanceMetricQuantityTypes)

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            healthStore.requestAuthorization(toShare: [], read: readTypes) { success, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: HealthKitError.workoutTypeUnavailable)
                }
            }
        }
    }

    func latestRunningWorkouts(limit: Int = 5) async throws -> [RunWorkout] {
        try await runningWorkouts(limit: limit)
    }

    func runningWorkouts(limit: Int = HKObjectQueryNoLimit) async throws -> [RunWorkout] {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.healthDataUnavailable
        }

        let runningPredicate = HKQuery.predicateForWorkouts(with: .running)
        let newestFirst = NSSortDescriptor(
            key: HKSampleSortIdentifierEndDate,
            ascending: false
        )

        let workouts = try await healthKitRunningWorkouts(
            predicate: runningPredicate,
            limit: limit,
            sortDescriptors: [newestFirst]
        )
        let workoutIDsWithRoute = try await workoutIDsWithRoutes(for: workouts)

        return workouts.map { workout in
            RunWorkout(workout: workout, hasRoute: workoutIDsWithRoute.contains(workout.uuid))
        }
    }

    func route(for workout: RunWorkout) async throws -> RunRoute? {
        let healthKitWorkout = try await healthKitWorkout(for: workout.id)
        guard let healthKitWorkout else {
            return nil
        }

        let routes = try await workoutRoutes(for: healthKitWorkout)
        var allLocations: [CLLocation] = []

        for route in routes {
            allLocations.append(contentsOf: try await locations(for: route))
        }

        guard !allLocations.isEmpty else {
            return nil
        }

        return RunRoute(locations: allLocations.sorted { $0.timestamp < $1.timestamp })
    }

    func metricSeries(for workout: RunWorkout) async throws -> [RunWorkoutMetricSeries] {
        let healthKitWorkout = try await healthKitWorkout(for: workout.id)
        guard let healthKitWorkout else {
            return []
        }

        var series: [RunWorkoutMetricSeries] = []

        for spec in Self.metricSampleSpecs {
            let samples = try await quantitySamples(for: healthKitWorkout, spec: spec)
            guard !samples.isEmpty else {
                continue
            }

            series.append(RunWorkoutMetricSeries(kind: spec.kind, samples: samples))
        }

        return series
    }

    private func healthKitWorkout(for id: UUID) async throws -> HKWorkout? {
        let workoutType = HKObjectType.workoutType()
        let predicate = HKQuery.predicateForObjects(with: Set([id]))

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: workoutType,
                predicate: predicate,
                limit: 1,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                continuation.resume(returning: samples?.first as? HKWorkout)
            }

            healthStore.execute(query)
        }
    }

    private func workoutRoutes(for workout: HKWorkout) async throws -> [HKWorkoutRoute] {
        let routeType = HKSeriesType.workoutRoute()
        let predicate = HKQuery.predicateForObjects(from: workout)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: routeType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                continuation.resume(returning: samples as? [HKWorkoutRoute] ?? [])
            }

            healthStore.execute(query)
        }
    }

    private func healthKitRunningWorkouts(
        predicate: NSPredicate,
        limit: Int,
        sortDescriptors: [NSSortDescriptor]?
    ) async throws -> [HKWorkout] {
        let workoutType = HKObjectType.workoutType()

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: workoutType,
                predicate: predicate,
                limit: limit,
                sortDescriptors: sortDescriptors
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                continuation.resume(returning: samples as? [HKWorkout] ?? [])
            }

            healthStore.execute(query)
        }
    }

    private func workoutIDsWithRoutes(for workouts: [HKWorkout]) async throws -> Set<UUID> {
        var workoutIDsWithRoute = Set<UUID>()

        for workout in workouts {
            if try await !workoutRoutes(for: workout).isEmpty {
                workoutIDsWithRoute.insert(workout.uuid)
            }
        }

        return workoutIDsWithRoute
    }

    private func locations(for route: HKWorkoutRoute) async throws -> [CLLocation] {
        try await withCheckedThrowingContinuation { continuation in
            var locations: [CLLocation] = []

            let query = HKWorkoutRouteQuery(route: route) { _, routeLocations, done, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                locations.append(contentsOf: routeLocations ?? [])

                if done {
                    continuation.resume(returning: locations)
                }
            }

            healthStore.execute(query)
        }
    }

    private func quantitySamples(
        for workout: HKWorkout,
        spec: HealthMetricSampleSpec
    ) async throws -> [RunWorkoutMetricSample] {
        let predicate = HKQuery.predicateForObjects(from: workout)
        let sortDescriptors = [
            NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        ]

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: spec.quantityType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: sortDescriptors
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let metricSamples = (samples as? [HKQuantitySample] ?? []).compactMap { sample in
                    spec.metricSample(from: sample)
                }

                continuation.resume(returning: metricSamples)
            }

            healthStore.execute(query)
        }
    }
}

private extension HealthKitManager {
    static var performanceMetricQuantityTypes: [HKQuantityType] {
        metricSampleSpecs.map(\.quantityType)
    }

    static var metricSampleSpecs: [HealthMetricSampleSpec] {
        [
            HealthMetricSampleSpec(
                kind: .heartRate,
                identifier: .heartRate,
                unit: HKUnit.count().unitDivided(by: .minute())
            ),
            HealthMetricSampleSpec(
                kind: .power,
                identifier: .runningPower,
                unit: .watt()
            ),
            HealthMetricSampleSpec(
                kind: .cadence,
                identifier: .stepCount,
                unit: .count()
            ) { sample, unit in
                let duration = sample.endDate.timeIntervalSince(sample.startDate)
                guard duration > 0 else {
                    return nil
                }

                return sample.quantity.doubleValue(for: unit) / duration * 60
            },
            HealthMetricSampleSpec(
                kind: .verticalOscillation,
                identifier: .runningVerticalOscillation,
                unit: .meter()
            ) { sample, unit in
                sample.quantity.doubleValue(for: unit) * 100
            },
            HealthMetricSampleSpec(
                kind: .groundContactTime,
                identifier: .runningGroundContactTime,
                unit: .second()
            ) { sample, unit in
                sample.quantity.doubleValue(for: unit) * 1_000
            },
            HealthMetricSampleSpec(
                kind: .strideLength,
                identifier: .runningStrideLength,
                unit: .meter()
            )
        ].compactMap(\.self)
    }
}

private struct HealthMetricSampleSpec {
    let kind: RunWorkoutMetricKind
    let quantityType: HKQuantityType
    let unit: HKUnit
    let value: (HKQuantitySample, HKUnit) -> Double?

    init?(
        kind: RunWorkoutMetricKind,
        identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        value: @escaping (HKQuantitySample, HKUnit) -> Double? = { sample, unit in
            sample.quantity.doubleValue(for: unit)
        }
    ) {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: identifier) else {
            return nil
        }

        self.kind = kind
        self.quantityType = quantityType
        self.unit = unit
        self.value = value
    }

    func metricSample(from sample: HKQuantitySample) -> RunWorkoutMetricSample? {
        guard let sampleValue = value(sample, unit),
              sampleValue.isFinite else {
            return nil
        }

        return RunWorkoutMetricSample(
            startDate: sample.startDate,
            endDate: sample.endDate,
            value: sampleValue
        )
    }
}

private extension RunWorkout {
    init(workout: HKWorkout, hasRoute: Bool = false) {
        let distanceMeters = workout.totalDistance?.doubleValue(for: .meter()) ?? 0
        let calories = workout.activeEnergyBurnedKilocalories
        let locationResolution = workout.resolveLocationType(hasRoute: hasRoute)

        self.init(
            id: workout.uuid,
            distanceMeters: distanceMeters,
            duration: workout.duration,
            startDate: workout.startDate,
            endDate: workout.endDate,
            calories: calories,
            averagePace: distanceMeters > 0 ? workout.duration / (distanceMeters / 1_000) : nil,
            locationType: locationResolution.type,
            locationTypeSource: locationResolution.source,
            indoorWorkoutRawValue: locationResolution.indoorWorkoutRawValue,
            hasRoute: hasRoute,
            sourceName: workout.sourceRevision.source.name,
            metadataText: workout.metadataDebugText
        )
    }
}

private extension HKWorkout {
    var activeEnergyBurnedKilocalories: Double? {
        guard let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            return nil
        }

        return statistics(for: energyType)?
            .sumQuantity()?
            .doubleValue(for: .kilocalorie())
    }

    func resolveLocationType(hasRoute: Bool) -> (
        type: RunLocationType,
        source: RunLocationTypeSource,
        indoorWorkoutRawValue: String?
    ) {
        let rawValue = metadata?[HKMetadataKeyIndoorWorkout]

        if let isIndoor = healthKitBoolValue(from: rawValue) {
            return (
                isIndoor ? .indoor : .outdoor,
                .healthKit,
                rawValue.map { "\($0)" }
            )
        }

        if hasRoute {
            return (.outdoor, .routeInferred, rawValue.map { "\($0)" })
        }

        return (.unknown, .unknown, rawValue.map { "\($0)" })
    }

    var metadataDebugText: String {
        let metadataPairs = (metadata ?? [:])
            .map { key, value in "\(key): \(value)" }
            .sorted()

        let indoorValue = metadata?[HKMetadataKeyIndoorWorkout].map { "\($0)" } ?? "missing"
        let lines = [
            "uuid: \(uuid.uuidString)",
            "activityType: \(workoutActivityType.rawValue)",
            "source: \(sourceRevision.source.name)",
            "bundleIdentifier: \(sourceRevision.source.bundleIdentifier)",
            "HKMetadataKeyIndoorWorkout: \(indoorValue)"
        ]

        return (lines + ["metadata:", metadataPairs.isEmpty ? "  <empty>" : metadataPairs.map { "  \($0)" }.joined(separator: "\n")])
            .joined(separator: "\n")
    }
}

private func healthKitBoolValue(from value: Any?) -> Bool? {
    guard let value else {
        return nil
    }

    if let bool = value as? Bool {
        return bool
    }

    if let number = value as? NSNumber {
        return number.boolValue
    }

    if let int = value as? Int {
        return int != 0
    }

    if let string = value as? String {
        switch string.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "true", "1", "yes":
            return true
        case "false", "0", "no":
            return false
        default:
            return nil
        }
    }

    return nil
}
