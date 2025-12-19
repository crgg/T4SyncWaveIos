//
//  NowPlayingMiniView.swift
//  T4SyncWave
//
//  Created by Ramon Gajardo on 12/17/25.
//

import SwiftUI

struct NowPlayingMiniView: View {
    let track: AudioTrack
    
    
    var body: some View {
        HStack {
            Image(systemName: "music.note")
            Text(track.title)
                .lineLimit(1)
            Spacer()
            Image(systemName: "play.fill")
        }
        .padding(8)
        .background(.ultraThinMaterial)
    }
}
//    #Preview {
//        NowPlayingMiniView(track: AudioTrack(title: "Porta Voz", artist: "Dale", url: URL(string: "https://www.youtube.com/watch?v=dQw4w9WgXcQ")!))
//    }
