import MapKit
import SwiftUI

struct RunDetailView: View {
    let workout: RunWorkout
    let selectedShoe: RunningShoe?
    @State private var routeViewModel = RunRouteViewModel()

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    RouteSection(state: routeViewModel.state)
                    RunDetailSummary(workout: workout, selectedShoe: selectedShoe)
                    RawHealthKitDataSection(workout: workout)
                    RunPerformanceMetricsSection(state: routeViewModel.state, workout: workout)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle(workout.distanceText)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .task {
            guard routeViewModel.state == .idle else {
                return
            }

            await routeViewModel.loadRoute(for: workout)
        }
    }
}

struct RouteSection: View {
    let state: RunRouteViewModel.State

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("路线")
                .font(.headline)

            switch state {
            case .idle, .loading:
                LoadingRouteCard()

            case .loaded(let route):
                RunRouteMap(route: route)

            case .empty:
                RouteUnavailableCard(
                    title: "没有路线数据",
                    message: "这次跑步可能是室内跑，或者 HealthKit 没有保存 GPS 路线。"
                )

            case .failed(let message):
                RouteUnavailableCard(title: "路线读取失败", message: message)
            }
        }
    }
}

struct RunRouteMap: View {
    let route: RunRoute

    var body: some View {
        Map(initialPosition: .region(route.mapRegion)) {
            MapPolyline(coordinates: route.coordinates)
                .stroke(.orange, lineWidth: 5)

            if let start = route.coordinates.first {
                Marker("起点", systemImage: "play.fill", coordinate: start)
                    .tint(.green)
            }

            if let end = route.coordinates.last {
                Marker("终点", systemImage: "flag.checkered", coordinate: end)
                    .tint(.red)
            }
        }
        .frame(height: 260)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.separator.opacity(0.35), lineWidth: 1)
        }
    }
}

struct RunStartLocationsMapSection: View {
    let workouts: [RunWorkout]
    @State private var viewModel = RunStartLocationsViewModel()

    private var taskID: String {
        workouts.map { $0.id.uuidString }.joined(separator: "|")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("跑步起点")
                    .font(.headline)

                Spacer()

                Text("随筛选联动")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            switch viewModel.state {
            case .idle, .loading:
                LoadingRouteCard()

            case .loaded(let startLocations):
                RunStartLocationsMap(startLocations: startLocations)

            case .empty:
                RouteUnavailableCard(
                    title: "没有可显示的起点",
                    message: "当前筛选下没有带路线的户外跑步，室内跑通常不会提供 GPS 起点。"
                )

            case .failed(let message):
                RouteUnavailableCard(title: "起点读取失败", message: message)
            }
        }
        .task(id: taskID) {
            await viewModel.loadStartLocations(for: workouts)
        }
    }
}

struct RunStartLocationsMap: View {
    let startLocations: [RunStartLocation]

    var body: some View {
        Map(initialPosition: .region(startLocations.latestCenteredMapRegion)) {
            ForEach(startLocations) { location in
                Marker(
                    location.date.formatted(date: .abbreviated, time: .omitted),
                    systemImage: "figure.run",
                    coordinate: location.coordinate
                )
                .tint(.blue)
            }
        }
        .mapControls {
            MapCompass()
            MapScaleView()
        }
        .mapControlVisibility(.visible)
        .frame(height: 280)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.separator.opacity(0.35), lineWidth: 1)
        }
    }

}

struct LoadingRouteCard: View {
    var body: some View {
        HStack(spacing: 12) {
            ProgressView()
            Text("正在读取路线...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(18)
        .cardStyle()
    }
}

struct RouteUnavailableCard: View {
    let title: String
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: "map")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.orange)

            Text(title.localized)
                .font(.headline)

            Text(message.localized)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .cardStyle()
    }
}

struct RunDetailSummary: View {
    let workout: RunWorkout
    let selectedShoe: RunningShoe?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("跑步详情")
                .font(.headline)

            VStack(spacing: 12) {
                DetailMetricRow(title: "日期", value: workout.startDate.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                DetailMetricRow(title: "时间", value: "\(workout.startDate.timeText) - \(workout.endDate.timeText)", systemImage: "clock")
                DetailMetricRow(title: "距离", value: workout.distanceText, systemImage: "road.lanes")
                DetailMetricRow(title: "时长", value: workout.durationText, systemImage: "timer")
                DetailMetricRow(title: "平均配速", value: workout.paceText, systemImage: "speedometer")
                DetailMetricRow(title: "卡路里", value: workout.caloriesText, systemImage: "flame")
                DetailMetricRow(title: "类型", value: workout.locationType.label, systemImage: workout.locationType.systemImage)
                DetailMetricRow(title: "跑鞋", value: selectedShoe?.name ?? "未绑定跑鞋", systemImage: "shoeprints.fill")
            }
            .padding(16)
            .cardStyle()
        }
    }
}

struct DetailMetricRow: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.orange)
                .frame(width: 28, height: 28)
                .background(.orange.opacity(0.12), in: Circle())

            Text(title.localized)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value.localized)
                .font(.subheadline.weight(.semibold))
                .multilineTextAlignment(.trailing)
        }
    }
}

struct RawHealthKitDataSection: View {
    let workout: RunWorkout

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("HealthKit 原始数据")
                .font(.headline)

            VStack(alignment: .leading, spacing: 10) {
                DetailMetricRow(title: "来源", value: workout.sourceName ?? "未知".localized, systemImage: "applewatch")
                DetailMetricRow(title: "识别结果", value: workout.locationType.label, systemImage: workout.locationType.systemImage)
                DetailMetricRow(title: "判断来源", value: workout.locationTypeSource.label, systemImage: "scope")
                DetailMetricRow(title: "Indoor 原始值", value: workout.indoorWorkoutRawValue ?? "missing", systemImage: "curlybraces")
                DetailMetricRow(title: "是否有路线", value: workout.hasRoute ? "是".localized : "否".localized, systemImage: "map")

                Text(workout.metadataText.isEmpty ? "没有 metadata".localized : workout.metadataText)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .padding(16)
            .cardStyle()
        }
    }
}

extension RunRoute {
    var mapRegion: MKCoordinateRegion {
        let coordinates = coordinates
        guard let first = coordinates.first else {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }

        var minLatitude = first.latitude
        var maxLatitude = first.latitude
        var minLongitude = first.longitude
        var maxLongitude = first.longitude

        for coordinate in coordinates {
            minLatitude = Swift.min(minLatitude, coordinate.latitude)
            maxLatitude = Swift.max(maxLatitude, coordinate.latitude)
            minLongitude = Swift.min(minLongitude, coordinate.longitude)
            maxLongitude = Swift.max(maxLongitude, coordinate.longitude)
        }

        let latitudeDelta = Swift.max((maxLatitude - minLatitude) * 1.35, 0.01)
        let longitudeDelta = Swift.max((maxLongitude - minLongitude) * 1.35, 0.01)

        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: (minLatitude + maxLatitude) / 2,
                longitude: (minLongitude + maxLongitude) / 2
            ),
            span: MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
        )
    }
}

extension Array where Element == RunStartLocation {
    private var defaultMapRadiusMeters: CLLocationDistance {
        25_000
    }

    var latestCenteredMapRegion: MKCoordinateRegion {
        guard let latestLocation = max(by: { $0.date < $1.date }) else {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }

        let nearbyLocations = locationsNearLatestStart(from: latestLocation)
        guard nearbyLocations.count > 1 else {
            return MKCoordinateRegion(
                center: latestLocation.coordinate,
                span: defaultMapSpan(centeredAt: latestLocation.coordinate)
            )
        }

        let first = nearbyLocations[0]
        var minLatitude = first.coordinate.latitude
        var maxLatitude = first.coordinate.latitude
        var minLongitude = first.coordinate.longitude
        var maxLongitude = first.coordinate.longitude

        for location in nearbyLocations {
            minLatitude = Swift.min(minLatitude, location.coordinate.latitude)
            maxLatitude = Swift.max(maxLatitude, location.coordinate.latitude)
            minLongitude = Swift.min(minLongitude, location.coordinate.longitude)
            maxLongitude = Swift.max(maxLongitude, location.coordinate.longitude)
        }

        let defaultSpan = defaultMapSpan(centeredAt: latestLocation.coordinate)
        let latitudeDelta = Swift.max((maxLatitude - minLatitude) * 1.8, defaultSpan.latitudeDelta)
        let longitudeDelta = Swift.max((maxLongitude - minLongitude) * 1.8, defaultSpan.longitudeDelta)

        return MKCoordinateRegion(
            center: latestLocation.coordinate,
            span: MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
        )
    }

    private func locationsNearLatestStart(from latestLocation: RunStartLocation) -> [RunStartLocation] {
        let latestCoordinate = CLLocation(
            latitude: latestLocation.coordinate.latitude,
            longitude: latestLocation.coordinate.longitude
        )

        return filter { location in
            let coordinate = CLLocation(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )

            return latestCoordinate.distance(from: coordinate) <= defaultMapRadiusMeters
        }
    }

    private func defaultMapSpan(centeredAt coordinate: CLLocationCoordinate2D) -> MKCoordinateSpan {
        let latitudeDelta = degrees(forMeters: defaultMapRadiusMeters * 2)
        let longitudeScale = Swift.max(cos(coordinate.latitude * .pi / 180), 0.2)
        let longitudeDelta = latitudeDelta / longitudeScale

        return MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
    }

    private func degrees(forMeters meters: CLLocationDistance) -> CLLocationDegrees {
        meters / 111_000
    }
}
