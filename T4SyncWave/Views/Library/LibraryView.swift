import SwiftUI

enum LibraryContext {
    case personal
    case group(groupmodel : GroupDetail)
}

struct LibraryView: View {
    @Environment(\.dismiss) var dismiss
    let context: LibraryContext
    @StateObject private var vm: LibraryViewModel

    init(context: LibraryContext) {
        self.context = context

        switch context {
        case .personal:
            _vm = StateObject(
                wrappedValue: LibraryViewModel( groupModel: nil)
                    
            )

        case .group(let groupmodel):
            _vm = StateObject(
                wrappedValue: LibraryViewModel(groupModel: groupmodel)
            )
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // 🎧 Mini Now Playing (personal)
                if let track = vm.selectedTrack {
                    LibraryMiniPlayer(
                        track: track,
                        isPlaying: vm.isPlaying,
                        onPlayPause: {
                            vm.togglePlay()
                        },
                        onStop: {
                            vm.stop()
                        }
                    )
                }

                List {

                    // 🎵 TRACKS
                    Section("Tracks") {
                        ForEach(vm.tracks) { track in
                            TrackRow(
                                track: track,
                                isPlaying: vm.selectedTrack?.id == track.id
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                handleSelection(track)
                            }
                        }
                    }

                    // 👥 SEND TO GROUP (solo en contexto group)
                    if case .group(let group) = context,
                       let selected = vm.selectedTrack {

                        Section {
                            Button {
                                sendToGroup(groupId: group.id, track: selected)
                            } label: {
                                Label("Send to Group", systemImage: "paperplane.fill")
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {

                // 📌 Title + subtitle
                ToolbarItem(placement: .principal) {
                    VStack {
                        Text("Library")
                            .font(.headline)
                        if case .group = context {
                            Text("Send music to group")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // ➕ Upload MP3
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        vm.pickMP3()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .tabItem {
            Label("Library", systemImage: "music.note.list")
        }
    }

    // 🎧 Tap = escuchar (SIEMPRE)
    private func handleSelection(_ track: AudioTrack) {
        if case .group(let group) = context {
          
            Task {
//                try? await GroupTrackService.shared.addTrack(
//                    groupID: group.id,
//                    trackID: track.id
//                )
                
                Task {
                    let response = try  await GroupTrackService.shared.addTrack(groupID: group.id, trackID: track.id )
                    if response.status {
                        dismiss()
                    }
                }
            }
            
        } else {
            
            vm.select(track)
        }
        
    }

    // 👥 Acción explícita = enviar al grupo
    private func sendToGroup(groupId: String, track: AudioTrack) {
//        Task {
//            try? await GroupTrackService.shared.addTrack(
//                groupId: groupId,
//                trackId: track.id
//            )
//        }
    }
    
  
}

