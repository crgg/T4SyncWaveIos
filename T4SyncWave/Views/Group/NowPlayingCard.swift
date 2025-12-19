//
//  NowPlayingCard.swift
//  T4SyncWave
//
//  Created by Ramon Gajardo on 12/18/25.
//

import Foundation
import SwiftUI

struct NowPlayingCard: View {

    let state: NowPlayingUIState?
    let currentTime: Double
    let duration: Double
    let isSeekEnabled: Bool
    let isRepeatEnabled: Bool
    let onAddMusic: () -> Void
    let onPlayPause: () -> Void
    let onSeek: (Double) -> Void
    var onBackward: (() -> Void)? = nil
    var onForward: (() -> Void)? = nil
    var onToggleRepeat: (() -> Void)? = nil
    
    // Helper para formatear tiempo mm:ss
    private func formatTime(_ seconds: Double) -> String {
        guard seconds.isFinite && seconds >= 0 else { return "0:00" }
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
    

    var body: some View {
        VStack(spacing: 16) {

            if let state {
                playingView(state)
            } else {
                emptyView
            }

        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
        )
        .padding(.horizontal)
    }
    
    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "music.note")
                .font(.system(size: 42))
                .foregroundColor(.secondary)

            Text("No music playing")
                .font(.headline)

            Text("Choose a track to start listening together")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button {
                onAddMusic()
            } label: {
                Label("Add Music", systemImage: "music.note.plus")
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity) // ← Centrar horizontalmente
        .padding(.vertical, 20)
    }
    private func playingView(_ state: NowPlayingUIState) -> some View {
        VStack(spacing: 12) {

            VStack(spacing: 4) {
                Text(state.trackTitle)
                    .font(.headline)
                    .lineLimit(1)

                if let artist = state.artist {
                    Text(artist)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Slider(
                value: Binding(
                    get: { currentTime },
                    set: { newValue in
                        onSeek(newValue)
                    }
                ),
                in: 0...max(duration, 1)
            )
            .disabled(!isSeekEnabled)
            
            // Tiempo actual / duración
            HStack {
                Text(formatTime(currentTime))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
                Spacer()
                Text(formatTime(duration))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
            }
            
            HStack(spacing: 32) {
                // 🔁 Botón Repetir
                Button(action: {
                    onToggleRepeat?()
                }) {
                    Image(systemName: isRepeatEnabled ? "repeat.1" : "repeat")
                        .font(.system(size: 20))
                        .frame(width: 36, height: 36)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundColor(isRepeatEnabled ? .accentColor : .primary)
                .disabled(!isSeekEnabled)
                .opacity(isSeekEnabled ? 1 : 0.4)
                
                Button(action: {
                    onBackward?()
                }) {
                    Image(systemName: "gobackward.15")
                        .font(.system(size: 24))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(!isSeekEnabled)
                .opacity(isSeekEnabled ? 1 : 0.4)

                Button(action: {
                    onPlayPause()
                }) {
                    Image(systemName: state.isPlaying
                          ? "pause.circle.fill"
                          : "play.circle.fill")
                        .font(.system(size: 48))
                        .frame(width: 56, height: 56)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Button(action: {
                    onForward?()
                }) {
                    Image(systemName: "goforward.15")
                        .font(.system(size: 24))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(!isSeekEnabled)
                .opacity(isSeekEnabled ? 1 : 0.4)
                
                // Spacer para balance visual
                Color.clear
                    .frame(width: 36, height: 36)
            }
            .foregroundColor(.primary)
        }
    }

}


