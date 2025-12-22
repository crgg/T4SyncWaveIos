//
//  PlaybackState.swift
//  T4SyncWave
//
//  Created by Ramon Gajardo on 12/15/25.
//

import Foundation
//struct PlaybackState: Codable {
//    let provider: String
//    let trackId: String
//    let positionMs: Int
//    let isPlaying: Bool
//    let timestamp: Int
//}
struct PlaybackState: Codable {
    let roomId: String
    let trackUrl : String
    let position: Double
    let isPlaying: Bool
    let timestamp: Int
}

/*
 {"type":"playback-state","room":"bulla","userName":"ramon7","position":11.00008998,"isPlaying":true,"timestamp":1765992768}
 📩 WS recibido: {"type":"playback-state","room":"bulla","userName":"ramon8","position":23.000098025,"isPlaying":true,"timestamp":1765993272,"trackUrl":"https://go2storage.s3.us-east-2.amazonaws.com/audio/42d9bfdf-7bd7-484b-8e43-f42c84ff1308.mp3"}

 {"type":"playback-state","trackUrl":"https://go2storage.s3.us-east-2.amazonaws.com/audio/df6bd099-f188-4cae-8265-b88ab99497f8.mp3","position":0,"isPlaying":true,"timestamp":1766115629}*/
struct PlaybackMessage: Codable {
    let type: String
    let room: String?
    let userName: String?
    let position: Double?
    let isPlaying: Bool
    let timestamp: Int
    let trackUrl : String
    
}
