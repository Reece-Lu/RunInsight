import CoreLocation
import SwiftUI

struct RunPerformanceMetricsSection: View {
    let state: RunRouteViewModel.State
    let workout: RunWorkout
    @State private var metricsViewModel = RunWorkoutMetricsViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("运动指标")
                    .font(.headline)

                Spacer()

                Text("路线数据优先")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 12) {
                routeMetricCard(\.elevationMetric, fallbackTitle: "海拔")
                healthMetricCard(for: .heartRate)
                routeMetricCard(\.paceMetric, fallbackTitle: "配速")
                healthMetricCard(for: .power)
                healthMetricCard(for: .cadence)
                healthMetricCard(for: .verticalOscillation)
                healthMetricCard(for: .groundContactTime)
                healthMetricCard(for: .strideLength)
                routeMetricCard(\.speedMetric, fallbackTitle: "速度")
            }
        }
        .task(id: workout.id) {
            guard metricsViewModel.state == .idle else {
                return
            }

            await metricsViewModel.loadMetrics(for: workout)
        }
    }

    @ViewBuilder
    private func routeMetricCard(
        _ keyPath: KeyPath<RunRouteAnalytics, RunMetricChart?>,
        fallbackTitle: String
    ) -> some View {
        switch state {
        case .loaded(let route):
            let analytics = RunRouteAnalytics(route: route, workout: workout)

            if let metric = analytics[keyPath: keyPath] {
                RunMetricChartCard(metric: metric)
            } else {
                RunMetricUnavailableCard(title: fallbackTitle, message: "这次跑步没有足够的路线数据。")
            }

        case .idle, .loading:
            RunMetricLoadingCard(title: fallbackTitle)

        case .empty:
            RunMetricUnavailableCard(title: fallbackTitle, message: "这次跑步没有路线数据。")

        case .failed(let message):
            RunMetricUnavailableCard(title: fallbackTitle, message: message)
        }
    }

    @ViewBuilder
    private func healthMetricCard(for kind: RunWorkoutMetricKind) -> some View {
        switch metricsViewModel.state {
        case .idle, .loading:
            RunMetricLoadingCard(title: kind.title)

        case .loaded(let series):
            if let metricSeries = series.first(where: { $0.kind == kind }),
               let metric = RunMetricChart(series: metricSeries, elapsedText: workout.duration.durationText) {
                RunMetricChartCard(metric: metric)
            } else {
                RunMetricUnavailableCard(title: kind.title, message: "这次跑步没有 \(kind.title) 数据。")
            }

        case .failed(let message):
            RunMetricUnavailableCard(title: kind.title, message: message)
        }
    }
}

struct RunMetricChartCard: View {
    let metric: RunMetricChart

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: metric.systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(metric.tint)
                    .frame(width: 30, height: 30)
                    .background(metric.tint.opacity(0.12), in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(metric.title)
                        .font(.headline)

                    Text(metric.primaryText)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(metric.tint)
                }

                Spacer()

                Text(metric.rangeText)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.trailing)
            }

            MiniMetricChart(metric: metric)
                .frame(height: 78)

            HStack {
                Text("0:00")
                Spacer()
                Text("Elapsed: \(metric.elapsedText)")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(16)
        .cardStyle()
    }
}

private struct RunMetricLoadingCard: View {
    let title: String

    var body: some View {
        HStack(spacing: 12) {
            ProgressView()

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text("正在读取数据...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(16)
        .cardStyle()
    }
}

private struct RunMetricUnavailableCard: View {
    let title: String
    let message: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis")
                .font(.headline)
                .foregroundStyle(.secondary)
                .frame(width: 30, height: 30)
                .background(Color.primary.opacity(0.06), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(16)
        .cardStyle()
    }
}

private struct MiniMetricChart: View {
    let metric: RunMetricChart
    @State private var selectedIndex: Int?

    private var displayValues: [Double] {
        metric.values.downsampled(to: 54)
    }

    private var valueRange: ClosedRange<Double> {
        guard let minValue = displayValues.min(),
              let maxValue = displayValues.max(),
              minValue != maxValue else {
            return 0...1
        }

        return minValue...maxValue
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottomLeading) {
                HStack(alignment: .bottom, spacing: 3) {
                    ForEach(Array(displayValues.enumerated()), id: \.offset) { index, value in
                        Capsule()
                            .fill(index == selectedIndex ? metric.tint : metric.tint.opacity(selectedIndex == nil ? 1 : 0.32))
                            .frame(
                                width: barWidth(in: geometry.size),
                                height: barHeight(for: value, in: geometry.size)
                            )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)

                if let selectedIndex,
                   displayValues.indices.contains(selectedIndex) {
                    selectionIndicator(
                        value: displayValues[selectedIndex],
                        index: selectedIndex,
                        size: geometry.size
                    )
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        selectedIndex = nearestIndex(for: value.location.x, width: geometry.size.width)
                    }
                    .onEnded { _ in
                        selectedIndex = nil
                    }
            )
        }
        .accessibilityLabel(metric.title)
    }

    private func barWidth(in size: CGSize) -> CGFloat {
        guard !displayValues.isEmpty else {
            return 2
        }

        return max((size.width - CGFloat(displayValues.count - 1) * 3) / CGFloat(displayValues.count), 2)
    }

    private func barHeight(for value: Double, in size: CGSize) -> CGFloat {
        let lowerBound = valueRange.lowerBound
        let upperBound = valueRange.upperBound
        let normalized = (value - lowerBound) / (upperBound - lowerBound)
        return max(size.height * CGFloat(normalized), 8)
    }

    private func nearestIndex(for xPosition: CGFloat, width: CGFloat) -> Int? {
        guard displayValues.count > 1, width > 0 else {
            return displayValues.isEmpty ? nil : 0
        }

        let clampedX = min(max(xPosition, 0), width)
        let progress = clampedX / width
        return min(max(Int((progress * CGFloat(displayValues.count - 1)).rounded()), 0), displayValues.count - 1)
    }

    @ViewBuilder
    private func selectionIndicator(value: Double, index: Int, size: CGSize) -> some View {
        let xPosition = xPosition(for: index, width: size.width)
        let labelOffset = min(max(xPosition - 42, 0), max(size.width - 84, 0))

        Rectangle()
            .fill(metric.tint.opacity(0.35))
            .frame(width: 1, height: size.height)
            .offset(x: xPosition)

        Text(metric.valueText(value))
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(metric.tint, in: Capsule())
            .offset(x: labelOffset, y: -size.height + 4)
    }

    private func xPosition(for index: Int, width: CGFloat) -> CGFloat {
        guard displayValues.count > 1 else {
            return 0
        }

        return CGFloat(index) / CGFloat(displayValues.count - 1) * width
    }
}

struct RunMetricChart {
    let title: String
    let primaryText: String
    let rangeText: String
    let elapsedText: String
    let systemImage: String
    let tint: Color
    let values: [Double]
    let valueText: (Double) -> String
}

extension RunMetricChart {
    init?(series: RunWorkoutMetricSeries, elapsedText: String) {
        guard let averageValue = series.averageValue,
              let minValue = series.minValue,
              let maxValue = series.maxValue,
              !series.values.isEmpty else {
            return nil
        }

        let kind = series.kind
        self.init(
            title: kind.title,
            primaryText: "平均 \(kind.formatAverage(averageValue))",
            rangeText: "\(kind.formatRangeValue(minValue))-\(kind.formatRangeValue(maxValue))",
            elapsedText: elapsedText,
            systemImage: kind.systemImage,
            tint: kind.tint,
            values: series.values,
            valueText: kind.formatPointValue(_:)
        )
    }
}

private extension RunWorkoutMetricKind {
    var title: String {
        switch self {
        case .heartRate:
            "心率"
        case .power:
            "功率"
        case .cadence:
            "步频"
        case .verticalOscillation:
            "垂直振幅"
        case .groundContactTime:
            "触地时间"
        case .strideLength:
            "步幅"
        }
    }

    var systemImage: String {
        switch self {
        case .heartRate:
            "heart.fill"
        case .power:
            "bolt.fill"
        case .cadence:
            "metronome.fill"
        case .verticalOscillation:
            "arrow.up.and.down"
        case .groundContactTime:
            "timer"
        case .strideLength:
            "ruler.fill"
        }
    }

    var tint: Color {
        switch self {
        case .heartRate:
            .red
        case .power:
            .yellow
        case .cadence:
            .purple
        case .verticalOscillation:
            .cyan
        case .groundContactTime:
            .orange
        case .strideLength:
            .blue
        }
    }

    func formatAverage(_ value: Double) -> String {
        formatPointValue(value)
    }

    func formatRangeValue(_ value: Double) -> String {
        switch self {
        case .heartRate:
            "\(Int(value.rounded()))"
        case .power:
            "\(Int(value.rounded()))"
        case .cadence:
            "\(Int(value.rounded()))"
        case .verticalOscillation:
            String(format: "%.1f", value)
        case .groundContactTime:
            "\(Int(value.rounded()))"
        case .strideLength:
            String(format: "%.2f", value)
        }
    }

    func formatPointValue(_ value: Double) -> String {
        switch self {
        case .heartRate:
            "\(Int(value.rounded())) bpm"
        case .power:
            "\(Int(value.rounded())) W"
        case .cadence:
            "\(Int(value.rounded())) spm"
        case .verticalOscillation:
            String(format: "%.1f cm", value)
        case .groundContactTime:
            "\(Int(value.rounded())) ms"
        case .strideLength:
            String(format: "%.2f m", value)
        }
    }
}

private struct RunRouteAnalytics {
    let route: RunRoute
    let workout: RunWorkout

    private var locations: [CLLocation] {
        route.locations.sorted { $0.timestamp < $1.timestamp }
    }

    var elevationMetric: RunMetricChart? {
        let elevations = locations
            .map(\.altitude)
            .filter { $0.isFinite }

        guard elevations.count > 1,
              let minElevation = elevations.min(),
              let maxElevation = elevations.max() else {
            return nil
        }

        return RunMetricChart(
            title: "海拔",
            primaryText: "爬升 \(Int(elevationGain.rounded())) m",
            rangeText: "\(Int(minElevation.rounded()))-\(Int(maxElevation.rounded())) m",
            elapsedText: workout.duration.durationText,
            systemImage: "mountain.2.fill",
            tint: .green,
            values: elevations,
            valueText: { "\(Int($0.rounded())) m" }
        )
    }

    var paceMetric: RunMetricChart? {
        let paces = segmentSamples.map(\.paceSecondsPerKilometer)
        guard paces.count > 1,
              let minPace = paces.min(),
              let maxPace = paces.max() else {
            return nil
        }

        return RunMetricChart(
            title: "配速",
            primaryText: "平均 \(workout.paceText)",
            rangeText: "\(minPace.paceText)-\(maxPace.paceText)",
            elapsedText: workout.duration.durationText,
            systemImage: "speedometer",
            tint: .cyan,
            values: paces,
            valueText: { $0.paceText }
        )
    }

    var speedMetric: RunMetricChart? {
        let speeds = segmentSamples.map(\.speedKilometersPerHour)
        guard speeds.count > 1,
              let minSpeed = speeds.min(),
              let maxSpeed = speeds.max() else {
            return nil
        }

        return RunMetricChart(
            title: "速度",
            primaryText: "平均 \(averageSpeedText)",
            rangeText: "\(minSpeed.speedText)-\(maxSpeed.speedText)",
            elapsedText: workout.duration.durationText,
            systemImage: "gauge.with.dots.needle.bottom.100percent",
            tint: .blue,
            values: speeds,
            valueText: { $0.speedText }
        )
    }

    private var elevationGain: CLLocationDistance {
        zip(locations, locations.dropFirst()).reduce(0) { total, pair in
            let gain = pair.1.altitude - pair.0.altitude
            return gain > 0 ? total + gain : total
        }
    }

    private var averageSpeedText: String {
        guard workout.duration > 0 else {
            return "-- km/h"
        }

        return (workout.distanceMeters / workout.duration * 3.6).speedText
    }

    private var segmentSamples: [RunRouteSegmentSample] {
        zip(locations, locations.dropFirst()).compactMap { previous, current in
            let duration = current.timestamp.timeIntervalSince(previous.timestamp)
            let distance = current.distance(from: previous)
            guard duration > 0, distance > 2 else {
                return nil
            }

            let speedMetersPerSecond = distance / duration
            guard speedMetersPerSecond.isFinite, speedMetersPerSecond > 0 else {
                return nil
            }

            return RunRouteSegmentSample(speedMetersPerSecond: speedMetersPerSecond)
        }
    }
}

private struct RunRouteSegmentSample {
    let speedMetersPerSecond: Double

    var speedKilometersPerHour: Double {
        speedMetersPerSecond * 3.6
    }

    var paceSecondsPerKilometer: TimeInterval {
        1_000 / speedMetersPerSecond
    }
}

private extension Double {
    var speedText: String {
        String(format: "%.1f km/h", self)
    }
}

private extension Array where Element == Double {
    func downsampled(to maxCount: Int) -> [Double] {
        guard count > maxCount, maxCount > 0 else {
            return self
        }

        return (0..<maxCount).map { index in
            let sourceIndex = Int((Double(index) / Double(maxCount - 1)) * Double(count - 1))
            return self[sourceIndex]
        }
    }
}
