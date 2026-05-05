//
//  RunWorkoutMetricsViewModel.swift
//  RunInsight
//
//  Created by Codex on 2026-05-05.
//

import Foundation

@MainActor
@Observable
final class RunWorkoutMetricsViewModel {
    enum State: Equatable {
        case idle
        case loading
        case loaded([RunWorkoutMetricSeries])
        case failed(String)
    }

    var state: State = .idle

    private let healthKitManager: HealthKitManager

    init(healthKitManager: HealthKitManager = HealthKitManager()) {
        self.healthKitManager = healthKitManager
    }

    func loadMetrics(for workout: RunWorkout) async {
        state = .loading

        do {
            try await healthKitManager.requestRunningWorkoutPermission()
            state = .loaded(try await healthKitManager.metricSeries(for: workout))
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
