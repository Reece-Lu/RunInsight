//
//  RunWorkoutMetricSeries.swift
//  RunInsight
//
//  Created by Codex on 2026-05-05.
//

import Foundation

enum RunWorkoutMetricKind: CaseIterable, Hashable {
    case heartRate
    case power
    case cadence
    case verticalOscillation
    case groundContactTime
    case strideLength
}

struct RunWorkoutMetricSample: Identifiable, Equatable {
    let id = UUID()
    let startDate: Date
    let endDate: Date
    let value: Double
}

struct RunWorkoutMetricSeries: Identifiable, Equatable {
    let kind: RunWorkoutMetricKind
    let samples: [RunWorkoutMetricSample]

    var id: RunWorkoutMetricKind {
        kind
    }

    var values: [Double] {
        samples.map(\.value)
    }

    var averageValue: Double? {
        guard !values.isEmpty else {
            return nil
        }

        return values.reduce(0, +) / Double(values.count)
    }

    var minValue: Double? {
        values.min()
    }

    var maxValue: Double? {
        values.max()
    }
}
