import Foundation

extension RunWorkout {
    var distanceText: String {
        distanceMeters.distanceText
    }

    var paceText: String {
        averagePace.paceText
    }

    var durationText: String {
        duration.durationText
    }

    var caloriesText: String {
        calories.caloriesText
    }

}

extension RunLocationType {
    var systemImage: String {
        switch self {
        case .outdoor:
            "map"
        case .indoor:
            "house"
        case .unknown:
            "questionmark.circle"
        }
    }
}

extension Double {
    var distanceText: String {
        if self >= 1_000 {
            return String(format: "%.2f km", self / 1_000)
        }

        return String(format: "%.0f m", self)
    }

    var caloriesText: String {
        String(format: "%.0f kcal", self)
    }
}

extension Optional where Wrapped == Double {
    var caloriesText: String {
        guard let self else {
            return "-- kcal"
        }

        return self.caloriesText
    }
}

extension TimeInterval {
    var durationText: String {
        let totalSeconds = Int(rounded())
        let hours = totalSeconds / 3_600
        let minutes = (totalSeconds % 3_600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }

        return String(format: "%d:%02d", minutes, seconds)
    }

    var paceText: String {
        let totalSeconds = Int(rounded())
        return String(format: "%d:%02d /km", totalSeconds / 60, totalSeconds % 60)
    }
}

extension Optional where Wrapped == TimeInterval {
    var paceText: String {
        guard let self else {
            return "--"
        }

        return self.paceText
    }
}

extension Date {
    var timeText: String {
        formatted(.dateTime.hour().minute())
    }
}

