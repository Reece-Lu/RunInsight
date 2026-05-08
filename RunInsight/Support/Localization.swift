//
//  Localization.swift
//  RunInsight
//
//  Created by Codex on 2026-05-08.
//

import Foundation

extension String {
    var localized: String {
        NSLocalizedString(self, comment: "")
    }
}
