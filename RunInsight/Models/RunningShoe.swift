//
//  RunningShoe.swift
//  RunInsight
//
//  Created by Codex on 2026-05-02.
//

import Foundation
import SwiftData

@Model
final class RunningShoe {
    @Attribute(.unique) var id: UUID
    var name: String
    @Attribute(.externalStorage) var photoData: Data?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        photoData: Data? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.photoData = photoData
        self.createdAt = createdAt
    }
}
