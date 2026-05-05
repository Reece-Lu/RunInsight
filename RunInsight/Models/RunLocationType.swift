//
//  RunLocationType.swift
//  RunInsight
//
//  Created by Codex on 2026-05-03.
//

import Foundation

enum RunLocationType: String, Codable, CaseIterable, Hashable {
    case outdoor
    case indoor
    case unknown

    var label: String {
        switch self {
        case .outdoor:
            "户外"
        case .indoor:
            "室内"
        case .unknown:
            "未知"
        }
    }
}
