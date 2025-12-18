//
//  RoomsView.swift
//  T4SyncWave
//
//  Created by Ramon Gajardo on 12/16/25.
//

import Foundation
import SwiftUI

struct RoomsView: View {

    @EnvironmentObject var session: SessionManager
    @StateObject private var vm: RoomsViewModel

    @State private var newRoomName = ""
    @State private var joinRoomId = ""

    init() {
        let session = SessionManager.shared
        _vm = StateObject(wrappedValue: RoomsViewModel(session: session))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {

                // Create Room
                VStack(alignment: .leading, spacing: 8) {
                    Text("Create a Room").font(.headline)

                    TextField("Room name", text: $newRoomName)
                        .textFieldStyle(.roundedBorder)

                    Button("Create") {
                        Task {
                            if let room = await vm.createRoom(name: newRoomName) {
                                goToRoom(room)
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(newRoomName.isEmpty)
                }

                Divider()

                // Join Room
                VStack(alignment: .leading, spacing: 8) {
                    Text("Join a Room").font(.headline)

                    TextField("Room ID", text: $joinRoomId)
                        .textFieldStyle(.roundedBorder)

                    Button("Join") {
                        Task {
                            if let room = await vm.joinRoom(roomId: joinRoomId) {
                                goToRoom(room)
                            }
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(joinRoomId.isEmpty)
                }

                Divider()

                // My Rooms
                List {
                    ForEach(vm.rooms) { room in
                        NavigationLink(room.name) {
                            LibraryView(context: .group(groupId: "", roomId: room.id, userName: session.user!.name))
                        }
                    }
                }
            }
            .padding()
            .navigationTitle("Rooms")
            .toolbar {
                Button("Logout") {
                    session.logout()
                }
            }
        }
    }

    private func goToRoom(_ room: Room) {
        // navegación inmediata usando NavigationLink ya existente
        joinRoomId = ""
        newRoomName = ""
    }
}
