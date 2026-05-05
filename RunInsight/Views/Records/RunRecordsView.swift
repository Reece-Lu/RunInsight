import SwiftUI

struct RunRecordsView: View {
    let viewModel: RunWorkoutsViewModel
    let workouts: [RunWorkout]
    let shoes: [RunningShoe]
    let selectedShoeID: (RunWorkout) -> UUID?
    let assignShoe: (UUID?, RunWorkout) -> Void
    let refreshImportedMetadata: () -> Void
    @State private var selectedSummaryRange: SummaryRange = .month
    @State private var selectedLocationFilter: RunLocationFilter = .all

    private var filteredWorkouts: [RunWorkout] {
        workouts.filter { workout in
            selectedSummaryRange.contains(workout)
                && selectedLocationFilter.contains(workout)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        if workouts.isEmpty {
                            LocalRunsEmptyCard()
                        } else {
                            RunFilterControls(
                                selectedSummaryRange: $selectedSummaryRange,
                                selectedLocationFilter: $selectedLocationFilter
                            )

                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("已同步跑步")
                                        .font(.headline)
                                        .foregroundStyle(.primary)

                                    Spacer()

                                    Text("自动识别户外/室内")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                if filteredWorkouts.isEmpty {
                                    FilteredRunsEmptyCard()
                                }

                                ForEach(filteredWorkouts) { workout in
                                    RunWorkoutCard(
                                        workout: workout,
                                        shoes: shoes,
                                        selectedShoeID: Binding(
                                            get: { selectedShoeID(workout) },
                                            set: { assignShoe($0, workout) }
                                        )
                                    )
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 28)
                }
                .refreshable {
                    await viewModel.checkForNewRuns(existingWorkoutIDs: Set(workouts.map(\.id)))
                    refreshImportedMetadata()
                }
            }
            .navigationTitle("记录")
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
}

struct RunWorkoutCard: View {
    let workout: RunWorkout
    let shoes: [RunningShoe]
    @Binding var selectedShoeID: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "figure.run")
                    .font(.headline)
                    .foregroundStyle(.orange)
                    .frame(width: 34, height: 34)
                    .background(.orange.opacity(0.12), in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.startDate, format: .dateTime.month().day().weekday(.wide))
                        .font(.headline)

                    Text("\(workout.startDate.timeText) - \(workout.endDate.timeText)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Label(workout.locationType.label, systemImage: workout.locationType.systemImage)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(workout.distanceText)
                    .font(.title3.weight(.bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            HStack {
                MetricView(title: "时长", value: workout.durationText, systemImage: "timer")
                Divider()
                MetricView(title: "配速", value: workout.paceText, systemImage: "speedometer")
                Divider()
                MetricView(title: "消耗", value: workout.caloriesText, systemImage: "flame")
            }
            .frame(height: 44)

            Picker("跑鞋", selection: $selectedShoeID) {
                Text("未绑定跑鞋").tag(Optional<UUID>.none)
                ForEach(shoes) { shoe in
                    Text(shoe.name).tag(Optional(shoe.id))
                }
            }
            .pickerStyle(.menu)
            .tint(.orange)

            NavigationLink {
                RunDetailView(workout: workout, selectedShoe: selectedShoe)
            } label: {
                HStack {
                    Label("查看路线和详情", systemImage: "map")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.orange)
                .padding(.top, 2)
            }
        }
        .padding(16)
        .cardStyle()
    }

    private var selectedShoe: RunningShoe? {
        guard let selectedShoeID else {
            return nil
        }

        return shoes.first { $0.id == selectedShoeID }
    }

}
