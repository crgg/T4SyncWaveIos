//
//  AudioTrack.swift
//  T4SyncWave
//
//  Created by Ramon Gajardo on 12/15/25.
//

import Foundation
//struct AudioTrack: Identifiable, Codable, Equatable {
//       let id: UUID
//       let title: String
//       let duration: Double
//       let url: String
//}
struct AudioResponse : Codable {
    let status: Bool
    let audio: [AudioTrack]
    let group : [GroupModel]?
}

struct AudioTrack: Codable, Identifiable {
    let id: String
    let group_id: String?
    let title: String
    let artist: String
    let file_url: String
    let duration_ms: Int
    let position: Int
    let added_by: String? // Opcional por si acaso el usuario es nulo
    let created_at: String
}
