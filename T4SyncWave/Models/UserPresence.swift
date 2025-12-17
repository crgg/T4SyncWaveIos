//
//  UserPresence.swift
//  T4SyncWave
//
//  Created by Ramon Gajardo on 12/15/25.
//

import Foundation
struct UserPresence: Identifiable {
    let id = UUID()
    let name: String
    let isHost: Bool
}
