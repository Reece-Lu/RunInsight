//
//  WorkoutShoeAssignment.swift
//  RunInsight
//
//  Created by Codex on 2026-05-02.
//

import Foundation
import SwiftData

@Model
final class WorkoutShoeAssignment {
    @Attribute(.unique) var workoutID: UUID
    var shoeID: UUID
    var createdAt: Date

    init(
        workoutID: UUID,
        shoeID: UUID,
        createdAt: Date = Date()
    ) {
        self.workoutID = workoutID
        self.shoeID = shoeID
        self.createdAt = createdAt
    }
}
