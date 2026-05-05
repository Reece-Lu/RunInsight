//
//  RunCoachModels.swift
//  RunInsight
//
//  Created by Codex on 2026-05-05.
//

import Foundation

enum RunCoachMessageRole {
    case user
    case assistant
}

struct RunCoachMessage: Identifiable, Equatable {
    let id = UUID()
    let role: RunCoachMessageRole
    let text: String
    let createdAt = Date()
}

struct RunCoachMetricSummary: Equatable {
    let title: String
    let average: String
    let range: String
    let sampleCount: Int
}

struct RunCoachAnalysisContext: Equatable {
    let workout: RunWorkout
    let selectedShoeName: String?
    let metricSummaries: [RunCoachMetricSummary]

    var promptText: String {
        var lines = [
            "跑步基础数据:",
            "- 日期: \(workout.startDate.formatted(date: .abbreviated, time: .shortened))",
            "- 距离: \(workout.distanceText)",
            "- 时长: \(workout.durationText)",
            "- 平均配速: \(workout.paceText)",
            "- 卡路里: \(workout.caloriesText)",
            "- 类型: \(workout.locationType.label)",
            "- 跑鞋: \(selectedShoeName ?? "未绑定跑鞋")",
            "- 是否有路线: \(workout.hasRoute ? "是" : "否")"
        ]

        if metricSummaries.isEmpty {
            lines.append("运动指标摘要: 暂无心率、功率、步频、步幅等样本。")
        } else {
            lines.append("运动指标摘要（发送的是统计摘要，不是逐点原始数据）:")
            for summary in metricSummaries {
                lines.append("- \(summary.title): 平均 \(summary.average), 范围 \(summary.range), 样本数 \(summary.sampleCount)")
            }
        }

        return lines.joined(separator: "\n")
    }
}
