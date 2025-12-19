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
    let currentTime: Double
    let duration: Double
    let isRepeatEnabled: Bool
    let onPlayPause: () -> Void
    let onStop: () -> Void
    let onToggleRepeat: () -> Void
    
    // Helper para formatear tiempo mm:ss
    private func formatTime(_ seconds: Double) -> String {
        guard seconds.isFinite && seconds >= 0 else { return "0:00" }
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {

                Image(systemName: "music.note")
                    .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    Text(track.title)
                        .font(.subheadline)
                        .lineLimit(1)

                    Text("\(formatTime(currentTime)) / \(formatTime(duration))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                }

                Spacer()
                
                // 🔁 Botón Repetir
                Button(action: onToggleRepeat) {
                    Image(systemName: isRepeatEnabled ? "repeat.1" : "repeat")
                        .font(.title3)
                        .foregroundColor(isRepeatEnabled ? .accentColor : .primary)
                }

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
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 4)
                    
                    Rectangle()
                        .fill(Color.accentColor)
                        .frame(width: duration > 0 ? geometry.size.width * (currentTime / duration) : 0, height: 4)
                }
                .cornerRadius(2)
            }
            .frame(height: 4)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal)
        .padding(.vertical, 6)
    }
}
