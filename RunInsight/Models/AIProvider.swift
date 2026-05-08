//
//  AIProvider.swift
//  RunInsight
//
//  Created by Codex on 2026-05-08.
//

import Foundation

enum AIProvider: String, CaseIterable, Identifiable {
    case openAI
    case qwen

    var id: String {
        rawValue
    }

    var displayName: String {
        switch self {
        case .openAI:
            "OpenAI"
        case .qwen:
            "通义千问".localized
        }
    }

    var apiTitle: String {
        switch self {
        case .openAI:
            "OpenAI API"
        case .qwen:
            "阿里云百炼 API".localized
        }
    }

    var keyStatusName: String {
        switch self {
        case .openAI:
            "OpenAI API Key"
        case .qwen:
            "DashScope API Key"
        }
    }

    var keyPlaceholder: String {
        switch self {
        case .openAI:
            "sk-..."
        case .qwen:
            "DashScope API Key"
        }
    }

    var keychainService: String {
        switch self {
        case .openAI:
            "RunInsight.OpenAI"
        case .qwen:
            "RunInsight.Qwen"
        }
    }

    var modelName: String {
        switch self {
        case .openAI:
            "gpt-5-mini"
        case .qwen:
            "qwen-plus"
        }
    }
}
