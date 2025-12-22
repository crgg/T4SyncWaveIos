//
//  PlaybackSyncService.swift
//  T4SyncWave
//
//  Created by Ramon Gajardo on 12/16/25.
//

import Foundation
 
@MainActor
final class PlaybackSyncService {

    static let shared = PlaybackSyncService()

    var isHost: Bool = false
    var roomId: String = ""

    private init() {}

    func broadcastPlayPause(
        isPlaying: Bool,
        position: Double
    ) {
        guard isHost else { return }

        let payload: [String: Any] = [
            "type": "playback-state",
            "roomId": roomId,
            "action": isPlaying ? "play" : "pause",
            "position": position
        ]

//        SignalingManager.shared.send(payload)
        print("📡 Broadcast:", payload)
    }
}
