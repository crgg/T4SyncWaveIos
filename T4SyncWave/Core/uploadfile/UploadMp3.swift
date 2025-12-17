//
//  UploadMp3.swift
//  T4SyncWave
//
//  Created by Ramon Gajardo on 12/15/25.
//

import Foundation
func upload(fileURL: URL) async throws -> AudioTrack {
    var request = URLRequest(url: URL(string: "https://api.tuapp.com/audio/upload")!)
    request.httpMethod = "POST"

    let (data, _) = try await URLSession.shared.upload(for: request, fromFile: fileURL)
    return try JSONDecoder().decode(AudioTrack.self, from: data)
}
