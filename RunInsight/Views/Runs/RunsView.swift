import SwiftUI

struct RunsView: View {
    let viewModel: RunWorkoutsViewModel
    let workouts: [RunWorkout]
    let refreshImportedMetadata: () -> Void
    let syncPendingRuns: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                content
            }
            .navigationTitle("RunInsight")
            .toolbar {
                Button {
                    Task {
                        await viewModel.checkForNewRuns(existingWorkoutIDs: Set(workouts.map(\.id)))
                        refreshImportedMetadata()
                    }
                } label: {
                    Label("刷新", systemImage: "arrow.clockwise")
                }
                .disabled(viewModel.state == .loading)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle:
            RunDashboardView(
                workouts: workouts,
                pendingNewWorkouts: viewModel.pendingNewWorkouts,
                syncPendingRuns: syncPendingRuns
            ) {
                await viewModel.checkForNewRuns(existingWorkoutIDs: Set(workouts.map(\.id)))
                refreshImportedMetadata()
            }

        case .loading:
            LoadingRunView()

        case .loaded:
            if workouts.isEmpty && viewModel.pendingNewWorkouts.isEmpty {
                EmptyRunsView {
                    await viewModel.checkForNewRuns(existingWorkoutIDs: Set(workouts.map(\.id)))
                    refreshImportedMetadata()
                }
            } else {
                RunDashboardView(
                    workouts: workouts,
                    pendingNewWorkouts: viewModel.pendingNewWorkouts,
                    syncPendingRuns: syncPendingRuns
                ) {
                    await viewModel.checkForNewRuns(existingWorkoutIDs: Set(workouts.map(\.id)))
                    refreshImportedMetadata()
                }
            }

        case .failed(let message):
            ErrorRunsView(message: message) {
                await viewModel.checkForNewRuns(existingWorkoutIDs: Set(workouts.map(\.id)))
            }
        }
    }
}

struct RunDashboardView: View {
    let workouts: [RunWorkout]
    let pendingNewWorkouts: [RunWorkout]
    let syncPendingRuns: () -> Void
    let refresh: () async -> Void
    @State private var selectedSummaryRange: SummaryRange = .month
    @State private var selectedLocationFilter: RunLocationFilter = .all

    private var filteredWorkouts: [RunWorkout] {
        workouts.filter { workout in
            selectedSummaryRange.contains(workout)
                && selectedLocationFilter.contains(workout)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if !pendingNewWorkouts.isEmpty {
                    NewRunsSyncBanner(
                        pendingCount: pendingNewWorkouts.count,
                        totalDistanceMeters: pendingNewWorkouts.reduce(0) { $0 + $1.distanceMeters },
                        sync: syncPendingRuns
                    )
                }

                if workouts.isEmpty {
                    LocalRunsEmptyCard()
                } else {
                    RunFilterControls(
                        selectedSummaryRange: $selectedSummaryRange,
                        selectedLocationFilter: $selectedLocationFilter
                    )

                    if filteredWorkouts.isEmpty {
                        FilteredRunsEmptyCard()
                    } else {
                        RunSummaryView(
                            title: selectedSummaryRange.summaryTitle,
                            workouts: filteredWorkouts
                        )

                        RunStartLocationsMapSection(workouts: filteredWorkouts)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 28)
        }
        .refreshable {
            await refresh()
        }
    }
}

struct RunSummaryView: View {
    let title: String
    let workouts: [RunWorkout]

    private var totalDistanceMeters: Double {
        workouts.reduce(0) { $0 + $1.distanceMeters }
    }

    private var totalDuration: TimeInterval {
        workouts.reduce(0) { $0 + $1.duration }
    }

    private var totalCalories: Double {
        workouts.compactMap(\.calories).reduce(0, +)
    }

    private var averagePace: TimeInterval? {
        guard totalDistanceMeters > 0 else {
            return nil
        }

        return totalDuration / (totalDistanceMeters / 1_000)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)

                    Text(totalDistanceMeters.distanceText)
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    Text("总距离")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "figure.run.circle.fill")
                    .font(.system(size: 46))
                    .foregroundStyle(.white, .orange)
                    .accessibilityHidden(true)
            }

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10)
                ],
                spacing: 10
            ) {
                SummaryMetricTile(title: "总时长", value: totalDuration.durationText, systemImage: "timer", tint: .blue)
                SummaryMetricTile(title: "平均配速", value: averagePace.paceText, systemImage: "speedometer", tint: .green)
                SummaryMetricTile(title: "卡路里", value: totalCalories.caloriesText, systemImage: "flame.fill", tint: .red)
                SummaryMetricTile(title: "记录数", value: "\(workouts.count) 次", systemImage: "list.bullet.clipboard", tint: .purple)
            }
        }
        .padding(18)
        .cardStyle()
    }
}

struct FilteredRunsEmptyCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.orange)

            Text("这个筛选下没有跑步")
                .font(.headline)

            Text("可以切换时间范围，或者选择全部、户外、室内来查看不同记录。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .cardStyle()
    }
}

struct NewRunsSyncBanner: View {
    let pendingCount: Int
    let totalDistanceMeters: Double
    let sync: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(.white, .blue)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 5) {
                    Text("检测到 \(pendingCount) 条新跑步记录")
                        .font(.headline)

                    Text("共 \(totalDistanceMeters.distanceText)。同步后会加入你的本地跑步数据库。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }

            Button {
                sync()
            } label: {
                Label("同步到 RunInsight", systemImage: "square.and.arrow.down")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(18)
        .cardStyle()
    }
}

struct LocalRunsEmptyCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: "tray")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.orange)

            Text("本地数据库还没有跑步记录")
                .font(.headline)

            Text("检测到新跑步后，点击同步就会把 HealthKit 的跑步记录复制到这里。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .cardStyle()
    }
}

struct LoadingRunView: View {
    var body: some View {
        VStack(spacing: 18) {
            ProgressView()
                .controlSize(.large)

            VStack(spacing: 6) {
                Text("正在读取跑步数据")
                    .font(.headline)
                Text("只会读取 HealthKit 中的跑步训练")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(24)
    }
}

struct EmptyRunsView: View {
    let retry: () async -> Void

    var body: some View {
        StateMessageView(
            title: "没有可同步的跑步记录",
            message: "本地数据库还没有跑步记录，HealthKit 中也暂时没有检测到新的跑步训练。其他运动类型会被自动忽略。",
            systemImage: "figure.run",
            actionTitle: "重新检测",
            action: retry
        )
    }
}

struct ErrorRunsView: View {
    let message: String
    let retry: () async -> Void

    var body: some View {
        StateMessageView(
            title: "无法读取健康数据",
            message: message,
            systemImage: "heart.text.square",
            actionTitle: "重试",
            action: retry
        )
    }
}

struct StateMessageView: View {
    let title: String
    let message: String
    let systemImage: String
    let actionTitle: String
    let action: () async -> Void

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: systemImage)
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(.orange)

            VStack(spacing: 8) {
                Text(title)
                    .font(.title3.weight(.semibold))
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button {
                Task {
                    await action()
                }
            } label: {
                Label(actionTitle, systemImage: "arrow.clockwise")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(24)
        .frame(maxWidth: 360)
    }
}
