//
//  Track.swift
//  T4SyncWave
//
//  Created by Ramon Gajardo on 12/17/25.
//

import Foundation
struct Track: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let artist: String?
    let url: URL
}

