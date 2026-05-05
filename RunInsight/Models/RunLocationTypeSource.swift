//
//  RunLocationTypeSource.swift
//  RunInsight
//
//  Created by Codex on 2026-05-04.
//

import Foundation

enum RunLocationTypeSource: String, Codable, Hashable {
    case healthKit
    case routeInferred
    case manual
    case unknown

    var label: String {
        switch self {
        case .healthKit:
            "HealthKit"
        case .routeInferred:
            "路线推断"
        case .manual:
            "手动"
        case .unknown:
            "未知"
        }
    }
}
