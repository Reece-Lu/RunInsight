//
//  ContentView.swift
//  RunInsight
//
//  Created by Yuwen on 2026-05-02.
//

import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RunWorkoutRecord.startDate, order: .reverse) private var runRecords: [RunWorkoutRecord]
    @Query(sort: \RunningShoe.createdAt, order: .reverse) private var shoes: [RunningShoe]
    @Query private var shoeAssignments: [WorkoutShoeAssignment]
    @State private var runViewModel = RunWorkoutsViewModel()

    var body: some View {
        TabView {
            RunsView(
                viewModel: runViewModel,
                workouts: importedWorkouts,
                refreshImportedMetadata: refreshImportedMetadata,
                syncPendingRuns: syncPendingRuns
            )
                .tabItem {
                    Label("跑步", systemImage: "figure.run")
                }

            RunRecordsView(
                viewModel: runViewModel,
                workouts: importedWorkouts,
                shoes: shoes,
                selectedShoeID: selectedShoeID(for:),
                assignShoe: assignShoe(_:to:),
                refreshImportedMetadata: refreshImportedMetadata
            )
                .tabItem {
                    Label("记录", systemImage: "list.bullet")
                }

            ShoesView(
                shoes: shoes,
                workouts: importedWorkouts,
                unassignedDistanceMeters: unassignedDistanceMeters(for: importedWorkouts),
                distanceMeters: distanceMeters(for:workouts:),
                runCount: runCount(for:workouts:)
            )
                .tabItem {
                    Label("跑鞋", systemImage: "shoeprints.fill")
                }

            RunCoachView(
                workouts: importedWorkouts,
                selectedShoeName: selectedShoeName(for:)
            )
                .tabItem {
                    Label("AI 教练", systemImage: "sparkles")
                }
        }
    }

    private var importedWorkouts: [RunWorkout] {
        runRecords.map(\.runWorkout)
    }

    private var importedWorkoutIDs: Set<UUID> {
        Set(runRecords.map(\.healthKitID))
    }

    private func selectedShoeID(for workout: RunWorkout) -> UUID? {
        shoeAssignments.first { $0.workoutID == workout.id }?.shoeID
    }

    private func selectedShoeName(for workout: RunWorkout) -> String? {
        guard let shoeID = selectedShoeID(for: workout) else {
            return nil
        }

        return shoes.first { $0.id == shoeID }?.name
    }

    private func assignShoe(_ shoeID: UUID?, to workout: RunWorkout) {
        if let assignment = shoeAssignments.first(where: { $0.workoutID == workout.id }) {
            if let shoeID {
                assignment.shoeID = shoeID
            } else {
                modelContext.delete(assignment)
            }
        } else if let shoeID {
            modelContext.insert(WorkoutShoeAssignment(workoutID: workout.id, shoeID: shoeID))
        }

        try? modelContext.save()
    }

    private func distanceMeters(for shoe: RunningShoe, workouts: [RunWorkout]) -> Double {
        workouts.reduce(0) { total, workout in
            selectedShoeID(for: workout) == shoe.id ? total + workout.distanceMeters : total
        }
    }

    private func runCount(for shoe: RunningShoe, workouts: [RunWorkout]) -> Int {
        workouts.filter { selectedShoeID(for: $0) == shoe.id }.count
    }

    private func unassignedDistanceMeters(for workouts: [RunWorkout]) -> Double {
        workouts.reduce(0) { total, workout in
            selectedShoeID(for: workout) == nil ? total + workout.distanceMeters : total
        }
    }

    private func syncPendingRuns() {
        let existingIDs = importedWorkoutIDs

        for workout in runViewModel.pendingNewWorkouts where !existingIDs.contains(workout.id) {
            modelContext.insert(RunWorkoutRecord(workout: workout))
        }

        try? modelContext.save()
        runViewModel.clearPendingRuns()
    }

    private func refreshImportedMetadata() {
        for healthKitWorkout in runViewModel.workouts {
            guard let record = runRecords.first(where: { $0.healthKitID == healthKitWorkout.id }) else {
                continue
            }

            record.sourceName = healthKitWorkout.sourceName
            record.metadataText = healthKitWorkout.metadataText
            record.indoorWorkoutRawValue = healthKitWorkout.indoorWorkoutRawValue
            record.hasRoute = healthKitWorkout.hasRoute

            if record.locationTypeSource != .manual {
                record.locationTypeRaw = healthKitWorkout.locationType.rawValue
                record.locationTypeSourceRaw = healthKitWorkout.locationTypeSource.rawValue
            }
        }

        try? modelContext.save()
    }
}

#Preview {
    ContentView()
}
