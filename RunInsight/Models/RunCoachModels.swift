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
        let shoeName = selectedShoeName ?? "未绑定跑鞋".localized
        let routeText = workout.hasRoute ? "是".localized : "否".localized
        var lines = [
            "跑步基础数据:".localized,
            String(format: NSLocalizedString("- 日期: %@", comment: ""), workout.startDate.formatted(date: .abbreviated, time: .shortened)),
            String(format: NSLocalizedString("- 距离: %@", comment: ""), workout.distanceText),
            String(format: NSLocalizedString("- 时长: %@", comment: ""), workout.durationText),
            String(format: NSLocalizedString("- 平均配速: %@", comment: ""), workout.paceText),
            String(format: NSLocalizedString("- 卡路里: %@", comment: ""), workout.caloriesText),
            String(format: NSLocalizedString("- 类型: %@", comment: ""), workout.locationType.label),
            String(format: NSLocalizedString("- 跑鞋: %@", comment: ""), shoeName),
            String(format: NSLocalizedString("- 是否有路线: %@", comment: ""), routeText)
        ]

        if metricSummaries.isEmpty {
            lines.append("运动指标摘要: 暂无心率、功率、步频、步幅等样本。".localized)
        } else {
            lines.append("运动指标摘要（发送的是统计摘要，不是逐点原始数据）:".localized)
            for summary in metricSummaries {
                lines.append(String(
                    format: NSLocalizedString("- %@: 平均 %@, 范围 %@, 样本数 %d", comment: ""),
                    summary.title,
                    summary.average,
                    summary.range,
                    summary.sampleCount
                ))
            }
        }

        return lines.joined(separator: "\n")
    }
}
