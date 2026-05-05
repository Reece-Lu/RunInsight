import Foundation

enum SummaryRange: CaseIterable, Hashable {
    case year
    case all
    case week
    case month

    var label: String {
        switch self {
        case .week:
            "一周"
        case .month:
            "一月"
        case .year:
            "一年"
        case .all:
            "全部"
        }
    }

    var summaryTitle: String {
        switch self {
        case .week:
            "最近一周"
        case .month:
            "最近一月"
        case .year:
            "最近一年"
        case .all:
            "全部跑步"
        }
    }

    func contains(_ workout: RunWorkout, now: Date = Date()) -> Bool {
        if self == .all {
            return true
        }

        guard let startDate = Calendar.current.date(byAdding: dateComponent, to: now) else {
            return true
        }

        return workout.startDate >= startDate
    }

    private var dateComponent: DateComponents {
        switch self {
        case .week:
            DateComponents(day: -7)
        case .month:
            DateComponents(month: -1)
        case .year:
            DateComponents(year: -1)
        case .all:
            DateComponents()
        }
    }
}

enum RunLocationFilter: CaseIterable, Hashable {
    case all
    case outdoor
    case indoor

    var label: String {
        switch self {
        case .all:
            "全部"
        case .outdoor:
            "户外"
        case .indoor:
            "室内"
        }
    }

    var systemImage: String {
        switch self {
        case .all:
            "line.3.horizontal.decrease.circle"
        case .outdoor:
            "map"
        case .indoor:
            "house"
        }
    }

    func contains(_ workout: RunWorkout) -> Bool {
        switch self {
        case .all:
            true
        case .outdoor:
            workout.locationType == .outdoor
        case .indoor:
            workout.locationType == .indoor
        }
    }
}

