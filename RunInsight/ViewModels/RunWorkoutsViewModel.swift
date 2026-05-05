//
//  RunWorkoutsViewModel.swift
//  RunInsight
//
//  Created by Codex on 2026-05-02.
//

import Foundation

@MainActor
@Observable
final class RunWorkoutsViewModel {
    enum State: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    var workouts: [RunWorkout] = []
    var pendingNewWorkouts: [RunWorkout] = []
    var state: State = .idle

    private let healthKitManager: HealthKitManager

    init(healthKitManager: HealthKitManager = HealthKitManager()) {
        self.healthKitManager = healthKitManager
    }

    func loadLatestRuns() async {
        state = .loading

        do {
            try await healthKitManager.requestRunningWorkoutPermission()
            workouts = try await healthKitManager.runningWorkouts()
            state = .loaded
        } catch {
            workouts = []
            state = .failed(error.localizedDescription)
        }
    }

    func checkForNewRuns(existingWorkoutIDs: Set<UUID>) async {
        state = .loading

        do {
            try await healthKitManager.requestRunningWorkoutPermission()
            let healthKitWorkouts = try await healthKitManager.runningWorkouts()
            workouts = healthKitWorkouts
            pendingNewWorkouts = healthKitWorkouts.filter { !existingWorkoutIDs.contains($0.id) }
            state = .loaded
        } catch {
            pendingNewWorkouts = []
            state = .failed(error.localizedDescription)
        }
    }

    func clearPendingRuns() {
        pendingNewWorkouts = []
    }
}
