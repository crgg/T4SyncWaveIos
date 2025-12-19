//
//  GroupTrackService.swift
//  T4SyncWave
//
//  Created by Ramon Gajardo on 12/17/25.
//

import Foundation


final class GroupTrackService {
    static let shared = GroupTrackService()
    private init() {}
    
    private let baseURL = URL(string: "https://t4videocall.t4ever.com")!
    
    func addTrack(groupID: String, trackID: String) async throws -> AddTrackResponse {
        try await APICore.shared.request(
            baseURL: baseURL,
            endpoint: "/api/audio_test/add-track-to-group",
            method: "POST",
            body: ["groupId": groupID,
                  "trackId" : trackID],
            requiredAuth: true
        )
    }
}
