//
//  TrackRow.swift
//  T4SyncWave
//
//  Created by Ramon Gajardo on 12/16/25.
//

import Foundation
import SwiftUI
struct TrackRow: View {

    let track: AudioTrack
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "music.note")
                .resizable()
                .frame(width: 40, height: 40)
                .foregroundColor(.blue)

            VStack(alignment: .leading) {
                Text(track.title)
                    .font(.headline)
                Text("\(Int(track.duration_ms / 1000)) sec")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            Image(systemName: "play.fill")
                .foregroundColor(.blue)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
        .onTapGesture {
            onTap()
        }
    }
}
