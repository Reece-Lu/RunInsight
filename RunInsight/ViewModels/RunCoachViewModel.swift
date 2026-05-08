//
//  RunCoachViewModel.swift
//  RunInsight
//
//  Created by Codex on 2026-05-05.
//

import Foundation

@MainActor
@Observable
final class RunCoachViewModel {
    enum State: Equatable {
        case idle
        case loading
        case failed(String)
    }

    var state: State = .idle
    var messages: [RunCoachMessage] = []
    var apiKeyStatusMessage = ""
    var hasAPIKey = false
    var selectedProvider: AIProvider {
        didSet {
            guard oldValue != selectedProvider else {
                return
            }

            UserDefaults.standard.set(selectedProvider.rawValue, forKey: Self.selectedProviderDefaultsKey)
            refreshAPIKeyStatus()
            resetConversation()
        }
    }

    private let openAIClient: OpenAIResponsesClient
    private let qwenClient: QwenChatCompletionsClient
    private let healthKitManager: HealthKitManager
    private var analysisContext: RunCoachAnalysisContext?

    init(
        openAIClient: OpenAIResponsesClient = OpenAIResponsesClient(),
        qwenClient: QwenChatCompletionsClient = QwenChatCompletionsClient(),
        healthKitManager: HealthKitManager = HealthKitManager()
    ) {
        self.openAIClient = openAIClient
        self.qwenClient = qwenClient
        self.healthKitManager = healthKitManager
        selectedProvider = UserDefaults.standard.selectedAIProvider
        refreshAPIKeyStatus()
    }

    func refreshAPIKeyStatus() {
        do {
            hasAPIKey = try keyStore.apiKey()?.isEmpty == false
            apiKeyStatusMessage = hasAPIKey
                ? String(format: NSLocalizedString("已配置 %@", comment: ""), selectedProvider.keyStatusName.localized)
                : String(format: NSLocalizedString("还没有配置 %@", comment: ""), selectedProvider.keyStatusName.localized)
        } catch {
            hasAPIKey = false
            apiKeyStatusMessage = error.localizedDescription
        }
    }

    func saveAPIKey(_ apiKey: String) {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else {
            return
        }

        do {
            try keyStore.save(apiKey: trimmedKey)
            refreshAPIKeyStatus()
        } catch {
            apiKeyStatusMessage = error.localizedDescription
        }
    }

    func deleteAPIKey() {
        do {
            try keyStore.deleteAPIKey()
            refreshAPIKeyStatus()
        } catch {
            apiKeyStatusMessage = error.localizedDescription
        }
    }

    func resetConversation() {
        messages = []
        analysisContext = nil
        state = .idle
    }

    func analyze(workout: RunWorkout, selectedShoeName: String?) async {
        await send(
            userText: "请先总结并点评这次跑步，给出亮点、风险和下次训练建议。".localized,
            workout: workout,
            selectedShoeName: selectedShoeName,
            appendUserMessage: false
        )
    }

    func ask(_ question: String, workout: RunWorkout, selectedShoeName: String?) async {
        let trimmedQuestion = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuestion.isEmpty else {
            return
        }

        await send(
            userText: trimmedQuestion,
            workout: workout,
            selectedShoeName: selectedShoeName,
            appendUserMessage: true
        )
    }

    private func send(
        userText: String,
        workout: RunWorkout,
        selectedShoeName: String?,
        appendUserMessage: Bool
    ) async {
        guard state != .loading else {
            return
        }

        do {
            let provider = selectedProvider
            guard let apiKey = try APIKeyStore(provider: provider).apiKey(), !apiKey.isEmpty else {
                hasAPIKey = false
                state = .failed(String(format: NSLocalizedString("请先填写 %@。", comment: ""), provider.keyStatusName.localized))
                return
            }

            state = .loading
            if appendUserMessage {
                messages.append(RunCoachMessage(role: .user, text: userText))
            }

            let context = try await context(for: workout, selectedShoeName: selectedShoeName)
            let response = try await response(
                provider: provider,
                apiKey: apiKey,
                instructions: Self.instructions,
                input: prompt(for: userText, context: context)
            )

            messages.append(RunCoachMessage(role: .assistant, text: response))
            state = .idle
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    private var keyStore: APIKeyStore {
        APIKeyStore(provider: selectedProvider)
    }

    private func response(
        provider: AIProvider,
        apiKey: String,
        instructions: String,
        input: String
    ) async throws -> String {
        switch provider {
        case .openAI:
            try await openAIClient.response(apiKey: apiKey, instructions: instructions, input: input)
        case .qwen:
            try await qwenClient.response(apiKey: apiKey, instructions: instructions, input: input)
        }
    }

    private func context(for workout: RunWorkout, selectedShoeName: String?) async throws -> RunCoachAnalysisContext {
        if let analysisContext, analysisContext.workout.id == workout.id {
            return analysisContext
        }

        try await healthKitManager.requestRunningWorkoutPermission()
        let metricSeries = try await healthKitManager.metricSeries(for: workout)
        let context = RunCoachAnalysisContext(
            workout: workout,
            selectedShoeName: selectedShoeName,
            metricSummaries: metricSeries.compactMap(RunCoachMetricSummary.init(series:))
        )
        analysisContext = context
        return context
    }

    private func prompt(for userText: String, context: RunCoachAnalysisContext) -> String {
        let transcript = messages
            .suffix(8)
            .map { message in
                let role = message.role == .user ? "用户".localized : "AI教练".localized
                return "\(role): \(message.text)"
            }
            .joined(separator: "\n\n")

        return """
        \("当前跑步数据如下：".localized)
        \(context.promptText)

        \("最近对话：".localized)
        \(transcript.isEmpty ? "暂无".localized : transcript)

        \("用户当前问题：".localized)
        \(userText)
        """
    }

    private static var instructions: String {
        if Locale.preferredLanguages.first?.hasPrefix("zh") == true {
            return """
            你是 RunInsight 里的中文跑步教练。你只能基于用户提供的跑步摘要、运动指标摘要和对话内容分析，不要声称看到了未提供的数据。
            回答要具体、温和、可执行。优先解释配速、心率、步频、步幅、功率、触地时间、垂直振幅等指标之间的关系。
            不提供医疗诊断；如果涉及疼痛、胸闷、异常心率或受伤风险，建议用户咨询专业人士。
            默认使用简洁中文，结构为：总结、观察、建议。不要输出过长内容。
            """
        }

        return """
        You are the running coach inside RunInsight. Analyze only the workout summary, metric summaries, and conversation provided by the user; do not claim to see data that was not provided.
        Be specific, supportive, and actionable. Prioritize relationships between pace, heart rate, cadence, stride length, power, ground contact time, and vertical oscillation.
        Do not provide medical diagnosis. If pain, chest tightness, abnormal heart rate, or injury risk appears, recommend consulting a qualified professional.
        Reply in concise English with this structure: Summary, Observations, Suggestions. Keep the answer brief.
        """
    }

    nonisolated fileprivate static let selectedProviderDefaultsKey = "RunInsight.SelectedAIProvider"
}

private extension UserDefaults {
    var selectedAIProvider: AIProvider {
        let rawValue = string(forKey: RunCoachViewModel.selectedProviderDefaultsKey)
        return rawValue.flatMap(AIProvider.init(rawValue:)) ?? .openAI
    }
}

private extension RunCoachMetricSummary {
    init?(series: RunWorkoutMetricSeries) {
        guard let average = series.averageValue,
              let minValue = series.minValue,
              let maxValue = series.maxValue else {
            return nil
        }

        self.init(
            title: series.kind.coachTitle,
            average: series.kind.coachValueText(average),
            range: "\(series.kind.coachValueText(minValue))-\(series.kind.coachValueText(maxValue))",
            sampleCount: series.samples.count
        )
    }
}

private extension RunWorkoutMetricKind {
    var coachTitle: String {
        switch self {
        case .heartRate:
            "心率".localized
        case .power:
            "功率".localized
        case .cadence:
            "步频".localized
        case .verticalOscillation:
            "垂直振幅".localized
        case .groundContactTime:
            "触地时间".localized
        case .strideLength:
            "步幅".localized
        }
    }

    func coachValueText(_ value: Double) -> String {
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
