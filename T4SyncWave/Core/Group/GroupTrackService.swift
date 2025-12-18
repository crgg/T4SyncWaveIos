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
    
    func addTrack(id: String, name: String) async throws -> GroupModel {
        try await APICore.shared.request(
            baseURL: baseURL,
            endpoint: "/api/groups/\(id)",
            method: "PUT",
            body: ["name": name],
            requiredAuth: true
        )
    }
}
