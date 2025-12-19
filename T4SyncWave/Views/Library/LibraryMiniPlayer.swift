//
//  MiniPlayerView.swift
//  T4SyncWave
//
//  Created by Ramon Gajardo on 12/16/25.
//

import Foundation
import SwiftUI

struct LibraryMiniPlayer: View {

    let track: AudioTrack
    let isPlaying: Bool
    let onPlayPause: () -> Void
    let onStop: () -> Void

    var body: some View {
        HStack(spacing: 12) {

            Image(systemName: "music.note")
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text(track.title)
                    .font(.subheadline)
                    .lineLimit(1)

                Text(isPlaying ? "Playing" : "Paused")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: onPlayPause) {
                Image(systemName: isPlaying
                      ? "pause.fill"
                      : "play.fill")
                    .font(.title3)
            }

            Button(action: onStop) {
                Image(systemName: "stop.fill")
                    .font(.title3)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal)
        .padding(.vertical, 6)
    }
}
