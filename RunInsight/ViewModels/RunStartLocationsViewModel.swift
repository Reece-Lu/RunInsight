//
//  RunStartLocationsViewModel.swift
//  RunInsight
//
//  Created by Codex on 2026-05-04.
//

import CoreLocation
import Foundation

@MainActor
@Observable
final class RunStartLocationsViewModel {
    enum State: Equatable {
        case idle
        case loading
        case loaded([RunStartLocation])
        case empty
        case failed(String)
    }

    var state: State = .idle

    private let healthKitManager: HealthKitManager

    init(healthKitManager: HealthKitManager = HealthKitManager()) {
        self.healthKitManager = healthKitManager
    }

    func loadStartLocations(for workouts: [RunWorkout]) async {
        let routedWorkouts = workouts.filter(\.hasRoute)
        guard !routedWorkouts.isEmpty else {
            state = .empty
            return
        }

        state = .loading

        do {
            var startLocations: [RunStartLocation] = []

            for workout in routedWorkouts {
                guard let route = try await healthKitManager.route(for: workout),
                      let start = route.locations.first else {
                    continue
                }

                startLocations.append(
                    RunStartLocation(
                        id: workout.id,
                        date: workout.startDate,
                        distanceMeters: workout.distanceMeters,
                        coordinate: start.coordinate
                    )
                )
            }

            state = startLocations.isEmpty ? .empty : .loaded(startLocations)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
