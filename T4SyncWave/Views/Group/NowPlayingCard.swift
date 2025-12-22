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
    var isListener: Bool = false // Listener mode - can't add music or control playback
    var isMuted: Bool = false // For listeners to mute locally
    let onAddMusic: () -> Void
    let onPlayPause: () -> Void
    let onSeek: (Double) -> Void
    var onBackward: (() -> Void)? = nil
    var onForward: (() -> Void)? = nil
    var onToggleRepeat: (() -> Void)? = nil
    var onToggleMute: (() -> Void)? = nil // For listeners
    
    // Helper para formatear tiempo mm:ss
    private func formatTime(_ seconds: Double) -> String {
        guard seconds.isFinite && seconds >= 0 else { return "0:00" }
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
    

    var body: some View {
        GeometryReader { geometry in
        VStack(spacing: 16) {

            if let state {
                playingView(state)
            } else {
                emptyView
            }

        }
        .padding()
            .frame(width: geometry.size.width - 32) // Ancho fijo menos padding
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
        )
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2) // Centrado exacto
        }
        .frame(height: isListener && state == nil ? 180 : (state == nil ? 200 : 220)) // Altura según estado
    }
    
    private var emptyView: some View {
        VStack(alignment: .center, spacing: 12) {
            if isListener {
                // Listener waiting for DJ
                Image(systemName: "waveform")
                    .font(.system(size: 42))
                    .foregroundColor(.secondary)
                    .symbolEffect(.pulse)

                Text("Waiting for DJ...")
                    .font(.headline)

                Text("The DJ will start playing music soon")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                ProgressView()
                    .padding(.top, 8)
            } else {
                // DJ can add music
            Image(systemName: "music.note")
                .font(.system(size: 42))
                .foregroundColor(.secondary)

            Text("No music playing")
                .font(.headline)

            Text("Choose a track to start listening together")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

                Button(action: onAddMusic) {
                Label("Add Music", systemImage: "music.note.plus")
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
        }
        }
        .frame(maxWidth: .infinity, alignment: .center)
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
            
            if isListener {
                // Listener controls - only mute button
                listenerControls(state)
            } else {
                // DJ controls - full control
                djControls(state)
            }
        }
    }
    
    // MARK: - DJ Controls (full control)
    private func djControls(_ state: NowPlayingUIState) -> some View {
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
            
                Button(action: {
                    onBackward?()
                }) {
                    Image(systemName: "gobackward.15")
                        .font(.system(size: 24))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

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
            
            // Spacer para balance visual
            Color.clear
                .frame(width: 36, height: 36)
        }
        .foregroundColor(.primary)
    }
    
    // MARK: - Listener Controls (only mute)
    private func listenerControls(_ state: NowPlayingUIState) -> some View {
        VStack(spacing: 12) {
            // Status indicator
            HStack(spacing: 8) {
                Circle()
                    .fill(state.isPlaying ? Color.green : Color.orange)
                    .frame(width: 8, height: 8)
                Text(state.isPlaying ? "DJ is playing" : "DJ paused")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 40) {
                // Mute button for listener
                Button(action: {
                    onToggleMute?()
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                            .font(.system(size: 32))
                            .frame(width: 56, height: 56)
                            .contentShape(Rectangle())
                        Text(isMuted ? "Unmute" : "Mute")
                            .font(.caption2)
            }
                }
                .buttonStyle(.plain)
                .foregroundColor(isMuted ? .red : .primary)
            }
            
            if isMuted {
                Text("Your audio is muted")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
    }

}


