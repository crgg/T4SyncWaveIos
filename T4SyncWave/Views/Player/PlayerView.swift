//
//  PlayerView.swift
//  T4SyncWave
//
//  Created by Ramon Gajardo on 12/15/25.
//

import Foundation
import SwiftUI
    
struct PlayerView: View {

    @StateObject private var vm = PlayerViewModel()

    var body: some View {
        VStack(spacing: 24) {

            // Título
            Text("SyncWave")
                .font(.largeTitle)
                .bold()

            // Rol
            Text(vm.isHost ? "🎧 You are the HOST" : "👂 Listening")
                .foregroundColor(vm.isHost ? .green : .blue)

            // Sync status
            Text("Status: \(vm.syncStatus)")
                .font(.caption)
                .foregroundColor(.gray)

            // Player
            Button(vm.audio.isPlaying ? "Pause" : "Play") {
                vm.audio.isPlaying ? vm.audio.pause() : vm.audio.play()
                vm.broadcastState()
            }
            .disabled(!vm.isHost)

//            Slider(
//                value: Binding(
//                    get: { vm.audio.syncTime() },
//                    set: {
//                        vm.audio.seek(to: $0)
//                        vm.broadcastState()
//                    }
//                ),
//                in: 0...vm.audio.duration
//            )
//            .disabled(!vm.isHost)

            Divider()

            // Usuarios
            VStack(alignment: .leading) {
                Text("Users in room")
                    .font(.headline)

                ForEach(vm.users) { user in
                    HStack {
                        Text(user.name)
                        if user.isHost {
                            Text("HOST")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                }
            }
        }
        .padding()
        .onAppear {
//            vm.audio.load(mp3Name: "demo")
        }
    }
}

