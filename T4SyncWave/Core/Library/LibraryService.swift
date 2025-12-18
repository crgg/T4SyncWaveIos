//
//  LibraryService.swift
//  T4SyncWave
//
//  Created by Ramon Gajardo on 12/17/25.
//

import Foundation


final class LibraryService {
    
    static let shared = LibraryService()
    
    private let baseURL = URL(string: "https://t4videocall.t4ever.com")!
    
    
    
    func listTracks() async throws -> AudioResponse {
        try await APICore.shared.request (
            baseURL: baseURL,
            endpoint: "api/audio_test/list_all_by_user",
            requiredAuth: true
        )
    }
    
    func addTrack(groupId : String ) async throws {
        
        
    }
    
    func uploadTrack(fileURL: URL) async throws {
        // multipart upload (siguiente paso)
    }
}
