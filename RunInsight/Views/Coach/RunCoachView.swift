import SwiftUI

struct RunCoachView: View {
    let workouts: [RunWorkout]
    let selectedShoeName: (RunWorkout) -> String?
    @State private var viewModel = RunCoachViewModel()
    @State private var selectedWorkoutID: UUID?
    @State private var isManagingAPIKey = false
    @State private var question = ""

    private var selectedWorkout: RunWorkout? {
        if let selectedWorkoutID,
           let workout = workouts.first(where: { $0.id == selectedWorkoutID }) {
            return workout
        }

        return workouts.first
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        apiKeyCard
                        workoutPickerSection

                        if let selectedWorkout {
                            privacyCard
                            actionSection(for: selectedWorkout)
                            conversationSection
                            questionSection(for: selectedWorkout)
                        } else {
                            emptyRunsCard
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 28)
                }
            }
            .navigationTitle("AI 教练")
            .toolbar {
                Button {
                    isManagingAPIKey = true
                } label: {
                    Label("管理密钥", systemImage: "key")
                }
            }
            .sheet(isPresented: $isManagingAPIKey) {
                OpenAIAPIKeyView(viewModel: viewModel)
            }
            .onAppear {
                if selectedWorkoutID == nil {
                    selectedWorkoutID = workouts.first?.id
                }
                viewModel.refreshAPIKeyStatus()
            }
            .onChange(of: workouts.map(\.id)) {
                if selectedWorkoutID == nil || selectedWorkout == nil {
                    selectedWorkoutID = workouts.first?.id
                }
            }
            .onChange(of: selectedWorkoutID) {
                viewModel.resetConversation()
            }
        }
    }

    private var apiKeyCard: some View {
        HStack(spacing: 12) {
            Image(systemName: viewModel.hasAPIKey ? "checkmark.seal.fill" : "key.fill")
                .font(.headline)
                .foregroundStyle(viewModel.hasAPIKey ? .green : .orange)
                .frame(width: 34, height: 34)
                .background((viewModel.hasAPIKey ? Color.green : Color.orange).opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text("OpenAI API")
                    .font(.headline)

                Text(viewModel.apiKeyStatusMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button("管理") {
                isManagingAPIKey = true
            }
            .buttonStyle(.bordered)
        }
        .padding(16)
        .cardStyle()
    }

    private var workoutPickerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("选择跑步")
                .font(.headline)

            if workouts.isEmpty {
                emptyRunsCard
            } else {
                Picker("选择跑步", selection: Binding(
                    get: { selectedWorkout?.id },
                    set: { selectedWorkoutID = $0 }
                )) {
                    ForEach(workouts) { workout in
                        Text(workoutPickerTitle(for: workout))
                            .tag(Optional(workout.id))
                    }
                }
                .pickerStyle(.menu)

                if let selectedWorkout {
                    SelectedRunCoachWorkoutCard(
                        workout: selectedWorkout,
                        shoeName: selectedShoeName(selectedWorkout)
                    )
                }
            }
        }
    }

    private var privacyCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lock.shield")
                .font(.headline)
                .foregroundStyle(.blue)
                .frame(width: 32, height: 32)
                .background(.blue.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 5) {
                Text("发送摘要，不发送原始轨迹")
                    .font(.headline)

                Text("AI 会收到距离、配速、时长、跑鞋和步幅、步频、心率等统计摘要。不会发送逐点 GPS 坐标或完整原始样本。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .cardStyle()
    }

    private func actionSection(for workout: RunWorkout) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                Task {
                    await viewModel.analyze(
                        workout: workout,
                        selectedShoeName: selectedShoeName(workout)
                    )
                }
            } label: {
                Label(viewModel.messages.isEmpty ? "分析这次跑步" : "重新分析", systemImage: "sparkles")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!viewModel.hasAPIKey || viewModel.state == .loading)

            if case .loading = viewModel.state {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("正在整理跑步摘要并请求 AI...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            if case .failed(let message) = viewModel.state {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var conversationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("对话")
                .font(.headline)

            if viewModel.messages.isEmpty {
                EmptyCoachConversationCard {
                    isManagingAPIKey = true
                }
            } else {
                VStack(spacing: 10) {
                    ForEach(viewModel.messages) { message in
                        RunCoachMessageBubble(message: message)
                    }
                }
            }
        }
    }

    private func questionSection(for workout: RunWorkout) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("继续提问")
                .font(.headline)

            HStack(alignment: .bottom, spacing: 10) {
                TextField("例如：我哪里需要改进？", text: $question, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...4)

                Button {
                    let currentQuestion = question
                    question = ""

                    Task {
                        await viewModel.ask(
                            currentQuestion,
                            workout: workout,
                            selectedShoeName: selectedShoeName(workout)
                        )
                    }
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.headline)
                        .frame(width: 38, height: 38)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.hasAPIKey || question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.state == .loading)
            }
        }
    }

    private var emptyRunsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: "figure.run")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.orange)

            Text("还没有可分析的跑步")
                .font(.headline)

            Text("先在跑步页同步 HealthKit 跑步记录，再回来让 AI 教练分析。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .cardStyle()
    }

    private func workoutPickerTitle(for workout: RunWorkout) -> String {
        "\(workout.startDate.formatted(date: .abbreviated, time: .omitted)) · \(workout.distanceText) · \(workout.paceText)"
    }
}

private struct SelectedRunCoachWorkoutCard: View {
    let workout: RunWorkout
    let shoeName: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.startDate, format: .dateTime.month().day().weekday(.wide))
                        .font(.headline)

                    Text("\(workout.startDate.timeText) - \(workout.endDate.timeText)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(workout.distanceText)
                    .font(.title3.weight(.bold))
            }

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10)
                ],
                spacing: 10
            ) {
                SummaryMetricTile(title: "时长", value: workout.durationText, systemImage: "timer", tint: .blue)
                SummaryMetricTile(title: "配速", value: workout.paceText, systemImage: "speedometer", tint: .green)
                SummaryMetricTile(title: "类型", value: workout.locationType.label, systemImage: workout.locationType.systemImage, tint: .orange)
                SummaryMetricTile(title: "跑鞋", value: shoeName ?? "未绑定", systemImage: "shoeprints.fill", tint: .purple)
            }
        }
        .padding(16)
        .cardStyle()
    }
}

private struct RunCoachMessageBubble: View {
    let message: RunCoachMessage

    private var isUser: Bool {
        message.role == .user
    }

    var body: some View {
        HStack {
            if isUser {
                Spacer(minLength: 40)
            }

            Text(message.text)
                .font(.subheadline)
                .foregroundStyle(isUser ? .white : .primary)
                .padding(12)
                .background(isUser ? Color.blue : Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .textSelection(.enabled)

            if !isUser {
                Spacer(minLength: 40)
            }
        }
    }
}

private struct EmptyCoachConversationCard: View {
    let manageAPIKey: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "sparkles")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(.orange)

            VStack(spacing: 6) {
                Text("还没有分析")
                    .font(.headline)

                Text("选择一次跑步后，点击分析即可生成总结。之后可以继续追问训练建议。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button(action: manageAPIKey) {
                Label("管理密钥", systemImage: "key")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity)
        .padding(18)
        .cardStyle()
    }
}

struct OpenAIAPIKeyView: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: RunCoachViewModel
    @State private var apiKey = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("API Key") {
                    SecureField("sk-...", text: $apiKey)
                        .autocorrectionDisabled()

                    Text(viewModel.apiKeyStatusMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Button("保存密钥") {
                        viewModel.saveAPIKey(apiKey)
                        apiKey = ""
                        dismiss()
                    }
                    .disabled(apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    if viewModel.hasAPIKey {
                        Button(role: .destructive) {
                            viewModel.deleteAPIKey()
                            apiKey = ""
                        } label: {
                            Label("清除密钥", systemImage: "trash")
                        }
                    }
                } footer: {
                    Text("密钥会保存到本机 Keychain。请求 OpenAI 时只发送当前选中跑步的摘要指标。")
                }
            }
            .navigationTitle("OpenAI 密钥")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}
