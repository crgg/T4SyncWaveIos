//
//  AudioTrack.swift
//  T4SyncWave
//
//  Created by Ramon Gajardo on 12/15/25.
//

import Foundation
struct AudioTrack: Identifiable, Codable, Equatable {
       let id: UUID
       let title: String
       let duration: Double
       let url: String
}
