//
//  RunRouteViewModel.swift
//  RunInsight
//
//  Created by Codex on 2026-05-02.
//

import Foundation

@MainActor
@Observable
final class RunRouteViewModel {
    enum State: Equatable {
        case idle
        case loading
        case loaded(RunRoute)
        case empty
        case failed(String)
    }

    var state: State = .idle

    private let healthKitManager: HealthKitManager

    init(healthKitManager: HealthKitManager = HealthKitManager()) {
        self.healthKitManager = healthKitManager
    }

    func loadRoute(for workout: RunWorkout) async {
        state = .loading

        do {
            let route = try await healthKitManager.route(for: workout)
            if let route, !route.locations.isEmpty {
                state = .loaded(route)
            } else {
                state = .empty
            }
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
