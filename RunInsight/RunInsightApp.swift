//
//  RunInsightApp.swift
//  RunInsight
//
//  Created by Yuwen on 2026-05-02.
//

import SwiftData
import SwiftUI

@main
struct RunInsightApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            RunWorkoutRecord.self,
            RunningShoe.self,
            WorkoutShoeAssignment.self
        ])
    }
}
