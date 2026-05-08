import SwiftUI

struct RunCoachView: View {
    let workouts: [RunWorkout]
    let selectedShoeName: (RunWorkout) -> String?
    @State private var viewModel = RunCoachViewModel()
    @State private var selectedWorkoutID: UUID?
    @State private var isManagingAPIKey = false
    @State private var question = ""
    @FocusState private var isQuestionFocused: Bool

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

                ScrollViewReader { scrollProxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            apiKeyCard
                            workoutPickerSection

                            if let selectedWorkout {
                                privacyCard
                                actionSection(for: selectedWorkout)
                                conversationSection
                                questionSection(for: selectedWorkout)
                                    .id(CoachScrollTarget.questionComposer)
                            } else {
                                emptyRunsCard
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, isQuestionFocused ? 112 : 28)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        isQuestionFocused = false
                    }
                    .onChange(of: isQuestionFocused) {
                        scrollToQuestionComposerIfNeeded(with: scrollProxy)
                    }
                }
            }
            .navigationTitle("AI 教练")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isManagingAPIKey = true
                    } label: {
                        Label("管理密钥", systemImage: "key")
                    }
                }
            }
            .sheet(isPresented: $isManagingAPIKey) {
                AIServiceSettingsView(viewModel: viewModel)
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
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: viewModel.hasAPIKey ? "checkmark.seal.fill" : "key.fill")
                    .font(.headline)
                    .foregroundStyle(viewModel.hasAPIKey ? .green : .orange)
                    .frame(width: 34, height: 34)
                    .background((viewModel.hasAPIKey ? Color.green : Color.orange).opacity(0.12), in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.selectedProvider.apiTitle)
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

            Picker("模型服务", selection: Binding(
                get: { viewModel.selectedProvider },
                set: { viewModel.selectedProvider = $0 }
            )) {
                ForEach(AIProvider.allCases) { provider in
                    Text(provider.displayName).tag(provider)
                }
            }
            .pickerStyle(.segmented)
            .disabled(viewModel.state == .loading)
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
                EmptyCoachConversationCard()
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

            CoachQuestionComposer(
                text: $question,
                isFocused: $isQuestionFocused,
                isEnabled: viewModel.hasAPIKey,
                isLoading: viewModel.state == .loading,
                send: {
                    submitQuestion(for: workout)
                }
            )
        }
    }

    private func submitQuestion(for workout: RunWorkout) {
        let currentQuestion = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard viewModel.hasAPIKey, !currentQuestion.isEmpty, viewModel.state != .loading else {
            return
        }

        question = ""
        isQuestionFocused = false

        Task {
            await viewModel.ask(
                currentQuestion,
                workout: workout,
                selectedShoeName: selectedShoeName(workout)
            )
        }
    }

    private func scrollToQuestionComposerIfNeeded(with scrollProxy: ScrollViewProxy) {
        guard isQuestionFocused else {
            return
        }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(220))
            withAnimation(.snappy(duration: 0.25)) {
                scrollProxy.scrollTo(CoachScrollTarget.questionComposer, anchor: .center)
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

private enum CoachScrollTarget {
    static let questionComposer = "coach-question-composer"
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
                SummaryMetricTile(title: "跑鞋", value: shoeName ?? "未绑定".localized, systemImage: "shoeprints.fill", tint: .purple)
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

private struct CoachQuestionComposer: View {
    @Binding var text: String
    let isFocused: FocusState<Bool>.Binding
    let isEnabled: Bool
    let isLoading: Bool
    let send: () -> Void

    private var trimmedText: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSend: Bool {
        isEnabled && !trimmedText.isEmpty && !isLoading
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            inputContainer
            sendButton
        }
        .padding(6)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.separator.opacity(0.25), lineWidth: 1)
        }
    }

    private var inputContainer: some View {
        HStack(alignment: .bottom, spacing: 8) {
            inputField
            clearButton
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .frame(minHeight: 50)
        .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(inputStrokeColor, lineWidth: 1)
        }
    }

    private var inputField: some View {
        TextField("问问这次跑步...", text: $text, axis: .vertical)
            .focused(isFocused)
            .font(.subheadline)
            .lineLimit(1...5)
            .submitLabel(.send)
            .autocorrectionDisabled(false)
            #if os(iOS)
            .textInputAutocapitalization(.sentences)
            #endif
            .disabled(!isEnabled || isLoading)
            .onSubmit {
                if canSend {
                    send()
                }
            }
    }

    @ViewBuilder
    private var clearButton: some View {
        if !trimmedText.isEmpty {
            Button {
                text = ""
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("清空输入")
        }
    }

    private var sendButton: some View {
        Button(action: send) {
            Image(systemName: isLoading ? "hourglass" : "paperplane.fill")
                .font(.headline)
                .frame(width: 50, height: 50)
                .foregroundStyle(canSend ? .white : .secondary)
                .background(canSend ? Color.blue : Color.primary.opacity(0.08), in: Circle())
        }
        .buttonStyle(.plain)
        .disabled(!canSend)
        .accessibilityLabel("发送问题")
    }

    private var inputStrokeColor: Color {
        isFocused.wrappedValue ? Color.blue.opacity(0.45) : Color.primary.opacity(0.08)
    }
}

private struct EmptyCoachConversationCard: View {
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
        }
        .frame(maxWidth: .infinity)
        .padding(18)
        .cardStyle()
    }
}

struct AIServiceSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: RunCoachViewModel
    @State private var apiKey = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("模型服务") {
                    Picker("服务商", selection: Binding(
                        get: { viewModel.selectedProvider },
                        set: { viewModel.selectedProvider = $0 }
                    )) {
                        ForEach(AIProvider.allCases) { provider in
                            Text(provider.displayName).tag(provider)
                        }
                    }
                    .pickerStyle(.segmented)
                    .disabled(viewModel.state == .loading)

                    LabeledContent("模型", value: viewModel.selectedProvider.modelName)
                }

                Section("API Key") {
                    SecureField(viewModel.selectedProvider.keyPlaceholder, text: $apiKey)
                        .autocorrectionDisabled()
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        #endif

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
                    Text("密钥会保存到本机 Keychain。请求当前服务商时只发送当前选中跑步的摘要指标，不发送完整 GPS 轨迹。")
                }
            }
            .navigationTitle("AI 服务")
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
