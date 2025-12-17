//
//  MiniPlayerView.swift
//  T4SyncWave
//
//  Created by Ramon Gajardo on 12/16/25.
//

import Foundation
import SwiftUI
struct MiniPlayerView: View {

    let title: String
    let isPlaying: Bool
    let onPlayPause: () -> Void

    var body: some View {
        HStack {
            Text(title)
                .lineLimit(1)

            Spacer()

            Button {
                onPlayPause()
            } label: {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
            }
        }
        .padding()
        .background(.ultraThinMaterial)
    }
}
